defmodule Extreme do
  use GenServer
  alias Extreme.Request
  require Logger
  alias Extreme.Response

  ## Client API

  @doc """
  Starts connection to EventStore using `connection_settings` and optional `opts`.
  """
  def start_link(connection_settings, opts \\[]) do
    GenServer.start_link __MODULE__, connection_settings, opts
  end

  @doc """
  Executes protobuf `message` against `server`. Returns:

  - {:ok, protobuf_message} on success .
  - {:error, :not_authenticated} on wrong credentials.
  - {:error, error_reason, protobuf_message} on failure.
  """
  def execute(server, message) do
    GenServer.call server, {:execute, message}    
  end


  @doc """
  Reads events specified in `read_events`, sends them to `subscriber` 
  and leaves `subscriber` subscribed per `subscribe` message.
  
  `subscriber` is process that will keep receiving {:on_event, event} messages.
  `read_events` :: Extreme.Messages.ReadStreamEvents
  `subscribe` :: Extreme.Messages.SubscribeToStream
  """
  def read_and_stay_subscribed(server, subscriber, stream, from_event_number \\ 0, per_page \\ 4096, resolve_link_tos \\ true, require_master \\ false) do
    GenServer.call server, {:read_and_stay_subscribed, subscriber, {stream, from_event_number, per_page, resolve_link_tos, require_master}}
  end

  @doc """
  Subscribe `subscriber` to `stream` using `server`.
  
  `subscriber` is process that will keep receiving {:new_event, event} messages.
  """
  def subscribe_to(server, subscriber, stream, resolve_link_tos \\ true) do
    GenServer.call server, {:subscribe_to, subscriber, stream, resolve_link_tos}
  end



  ## Server Callbacks

  @subscriptions_sup Extreme.SubscriptionsSupervisor

  def init(connection_settings) do
    user = Keyword.fetch! connection_settings, :username
    pass = Keyword.fetch! connection_settings, :password
    GenServer.cast self, {:connect, connection_settings, 1}
    {:ok, sup} = Extreme.SubscriptionsSupervisor.start_link self
    {:ok, %{socket: nil, pending_responses: %{}, subscriptions: %{}, subscriptions_sup: sup, credentials: %{user: user, pass: pass}, received_data: <<>>, should_receive: nil}}
  end

  def handle_cast({:connect, connection_settings, attempt}, state) do
    db_type = Keyword.get(connection_settings, :db_type, :node)
    case connect db_type, connection_settings, attempt do
      {:ok, socket} -> {:noreply, %{state|socket: socket}}
      error         -> {:stop, error, state}
    end
  end

  defp connect(:cluster, connection_settings, attempt) do
    {:ok, host, port} = Extreme.ClusterConnection.get_node connection_settings
    connect(host, port, connection_settings, attempt)
  end
  defp connect(:node, connection_settings, attempt) do
    host = Keyword.fetch! connection_settings, :host
    port = Keyword.fetch! connection_settings, :port
    connect(host, port, connection_settings, attempt)
  end
  defp connect(host, port, connection_settings, attempt) do
    Logger.info "Connecting Extreme to #{host}:#{port}"
    opts = [:binary, active: :once]
    case :gen_tcp.connect(String.to_char_list(host), port, opts) do
      {:ok, socket} -> 
        Logger.info "Successfuly connected to EventStore @ #{host}:#{port}"
        :timer.send_after 1_000, :send_ping
        {:ok, socket}
      _             -> 
        max_attempts = Keyword.get connection_settings, :max_attempts, :infinity
        reconnect = case max_attempts do
          :infinity -> true
          max when attempt <= max -> true
          _ -> false 
        end
        if reconnect do
          reconnect_delay = Keyword.get connection_settings, :reconnect_delay, 1_000
          Logger.warn "Error connecting to EventStore @ #{host}:#{port}. Will retry in #{reconnect_delay} ms."
          :timer.sleep reconnect_delay
          db_type = Keyword.get(connection_settings, :db_type, :node)
          connect db_type, connection_settings, attempt + 1
        else
          {:error, :max_attempt_exceeded}
        end
    end
  end

  def handle_call({:execute, protobuf_msg}, from, state) do
    {message, correlation_id} = Request.prepare protobuf_msg, state.credentials
    #Logger.debug "Will execute #{inspect protobuf_msg}"
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end
  def handle_call({:read_and_stay_subscribed, subscriber, params}, _from, state) do
    {:ok, subscription} = Extreme.SubscriptionsSupervisor.start_subscription state.subscriptions_sup, subscriber, params
    #Logger.debug "Subscription is: #{inspect subscription}"
    {:reply, {:ok, subscription}, state}
  end
  def handle_call({:subscribe_to, subscriber, stream, resolve_link_tos}, _from, state) do
    {:ok, subscription} = Extreme.SubscriptionsSupervisor.start_subscription state.subscriptions_sup, subscriber, stream, resolve_link_tos
    #Logger.debug "Subscription is: #{inspect subscription}"
    {:reply, {:ok, subscription}, state}
  end
  def handle_call({:subscribe, subscriber, msg}, from, state) do
    #Logger.debug "Subscribing #{inspect subscriber} with: #{inspect msg}"
    {message, correlation_id} = Request.prepare msg, state.credentials
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    state = put_in state.subscriptions, Map.put(state.subscriptions, correlation_id, subscriber)
    {:noreply, state}
  end

  def handle_info(:send_ping, state) do
    message = Request.prepare :ping
    :ok = :gen_tcp.send state.socket, message
    {:noreply, state}
  end
  def handle_info({:tcp, socket, pkg}, state) do
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    state = process_package pkg, state
    {:noreply, state}
  end


  # This package carries message from it's start. Process it and return new `state`
  defp process_package(<<message_length :: 32-unsigned-little-integer, content :: binary>>, %{socket: _socket, received_data: <<>>} = state) do
    #Logger.debug "Processing package with message_length of: #{message_length}"
    slice_content(message_length, content)
    |> process_content(state)
  end
  # Process package for unfinished message. Process it and return new `state`
  defp process_package(pkg, %{socket: _socket} = state) do
    #Logger.debug "Processing next package. We need #{state.should_receive} bytes and we have collected #{byte_size(state.received_data)} so far and we have #{byte_size(pkg)} more"
    slice_content(state.should_receive, state.received_data <> pkg)
    |> process_content(state)
  end

  defp slice_content(message_length, content) do 
    if byte_size(content) < message_length do
      #Logger.debug "We have unfinished message of length #{message_length}(#{byte_size(content)}): #{inspect content}"
      {:unfinished_message, message_length, content}
    else
      case content do
        <<message :: binary - size(message_length), next_message :: binary>> -> {message, next_message} 
        <<message :: binary - size(message_length)>>                         -> {message, <<>>}
      end
    end
  end

  defp process_content({:unfinished_message, expected_message_length, data}, state) do 
    %{state|should_receive: expected_message_length, received_data: data}
  end
  defp process_content({message, <<>>}, state) do 
  #Logger.debug "Processing single message: #{inspect message} and we have already received: #{inspect state.received_data}"
    state = process_message(message, state)
    #Logger.debug "After processing content state is #{inspect state}"
    %{state|should_receive: nil, received_data: <<>>}
  end
  defp process_content({message, rest}, state) do 
  #Logger.debug "Processing message: #{inspect message}"
  #Logger.debug "But we have something else in package: #{inspect rest}"
    state = process_message message, %{state|should_receive: nil, received_data: <<>>}
    process_package rest, state
  end

  defp process_message(message, state) do
    #"Let's finally process whole message: #{inspect message}"
    Response.parse(message)
    |> respond(state)
  end

  defp respond({:pong, _correlation_id}, state) do
    #Logger.debug "#{inspect self} got :pong"
    :timer.send_after 1_000, :send_ping
    state
  end
  defp respond({:heartbeat_request, correlation_id}, state) do
    #Logger.debug "#{inspect self} Tick-Tack"
    message = Request.prepare :heartbeat_response, correlation_id
    :ok = :gen_tcp.send state.socket, message
    %{state|pending_responses: state.pending_responses}
  end
  defp respond({:error, :not_authenticated, correlation_id}, state) do
    {:error, :not_authenticated}
    |> respond_with(correlation_id, state)
  end
  defp respond({_auth, correlation_id, response}, state) do
    response
    |> respond_with(correlation_id, state)
  end

  defp respond_with(response, correlation_id, state) do
    #Logger.debug "Responding with response: #{inspect response}"
    case Map.get(state.pending_responses, correlation_id) do
      nil -> 
        respond_to_subscription(response, correlation_id, state.subscriptions)
        state
      from -> 
        :ok = GenServer.reply from, Response.reply(response)
        pending_responses = Map.delete state.pending_responses, correlation_id
        %{state|pending_responses: pending_responses}
    end
  end

  defp respond_to_subscription(response, correlation_id, subscriptions) do
    case Map.get(subscriptions, correlation_id) do
      nil -> :ok #Logger.error "Can't find correlation_id #{inspect correlation_id} for response #{inspect response}"
      subscription -> GenServer.cast subscription, Response.reply(response)
    end
  end
end

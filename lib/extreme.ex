defmodule Extreme do
  @moduledoc """
  Extreme module is main communication point with EventStore using tcp connection. Extreme is implemented using 
  GenServer and is OTP compatible. If client is disconnected from server we are not trying to reconnect, 
  instead you should rely on your supervisor.  For example:
  
      defmodule MyApp.Supervisor do
        use Supervisor
      
        def start_link, 
          do: Supervisor.start_link __MODULE__, :ok
      
        @event_store MyApp.EventStore
        
        def init(:ok) do
          event_store_settings = Application.get_env :my_app, :event_store
      
          children = [
            worker(Extreme, [event_store_settings, [name: @event_store]]),
            # ... other workers / supervisors
          ]
          supervise children, strategy: :one_for_one
        end
      end
  
  You can manually start adapter as well (as you can see in test file):
  
      {:ok, server} = Application.get_env(:extreme, :event_store) |> Extreme.start_link
  
  From now on, `server` pid is used for further communication. Since we are relying on supervisor to reconnect,
  it is wise to name `server` as we did in example above.
  """
  use GenServer
  alias Extreme.Request
  require Logger
  alias Extreme.Response

  ## Client API

  @doc """
  Starts connection to EventStore using `connection_settings` and optional `opts`.

  Extreme can connect to single ES node or to cluster specified with node IPs and ports.
  
  Example for connecting to single node:
  
      config :extreme, :event_store,
        db_type: :node, 
        host: "localhost", 
        port: 1113, 
        username: "admin", 
        password: "changeit",
        reconnect_delay: 2_000,
        max_attempts: :infinity
  
    * `db_type` - defaults to :node, thus it can be omitted
    * `host` - check EXT IP setting of your EventStore
    * `port` - check EXT TCP PORT setting of your EventStore
    * `reconnect_delay` - in ms. Defaults to 1_000. If tcp connection fails this is how long it will wait for reconnection.
    * `max_attempts` - Defaults to :infinity. Specifies how many times we'll try to connect to EventStore
  
  
  Example for connecting to cluster:
  
      config :extreme, :event_store,
        db_type: :cluster,
        gossip_timeout: 300,
        nodes: [
          %{host: "10.10.10.29", port: 2113},
          %{host: "10.10.10.28", port: 2113},
          %{host: "10.10.10.30", port: 2113}
        ],
        username: "admin", 
        password: "changeit"
  
    * `gossip_timeout` - in ms. Defaults to 1_000. We are iterating through `nodes` list, asking for cluster member details.
  This setting represents timeout for gossip response before we are asking next node from `nodes` list for cluster details.
    * `nodes` - Mandatory for cluster connection. Represents list of nodes in the cluster as we know it
      * `host` - should be EXT IP setting of your EventStore node
      * `port` - should be EXT HTTP PORT setting of your EventStore node
  
  Example of connection to cluster via DNS lookup
  
      config :extreme, :event_store,
       db_type: :cluster_dns, 
       gossip_timeout: 300,
       host: "es-cluster.example.com", # accepts char list too, this whould be multy A record host enrty in your nameserver
       port: 2113, # the external gossip port
       username: "admin", 
       password: "changeit",
       max_attempts: :infinity 
  
  When `cluster` mode is used, adapter goes thru `nodes` list and tries to gossip with node one after another
  until it gets response about nodes. Based on nodes information from that response it ranks their statuses and chooses
  the best candidate to connect to. For the way ranking is done, take a look at `lib/cluster_connection.ex`:
  
      defp rank_state("Master"), do: 1
      defp rank_state("PreMaster"), do: 2
      defp rank_state("Slave"), do: 3
      defp rank_state("Clone"), do: 4
      defp rank_state("CatchingUp"), do: 5
      defp rank_state("PreReplica"), do: 6
      defp rank_state("Unknown"), do: 7
      defp rank_state("Initializing"), do: 8
  
  Note that above will work with same procedure with `cluster_dns` mode turned on, since internally it will get ip addresses to witch same connection procedure will be used.
  
  Once client is disconnected from EventStore, supervisor should respawn it and connection starts over again.
  """
  def start_link(connection_settings, opts \\[]), 
    do: GenServer.start_link(__MODULE__, connection_settings, opts)

  @doc """
  Executes protobuf `message` against `server`. Returns:

  - {:ok, protobuf_message} on success .
  - {:error, :not_authenticated} on wrong credentials.
  - {:error, error_reason, protobuf_message} on failure.

  EventStore uses ProtoBuf for taking requests and sending responses back. 
  We are using [exprotobuf](https://github.com/bitwalker/exprotobuf) to deal with them. 
  List and specification of supported protobuf messages can be found in `include/event_store.proto` file.
  
  Instead of wrapping each and every request in elixir function, we are using `execute/2` function that takes server pid and request message:
  
      {:ok, response} = Extreme.execute server, write_events()
  
  where `write_events` can be helper function like:
  
      alias Extreme.Messages, as: ExMsg
  
      defp write_events(stream \\ "people", events \\ [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]) do
        proto_events = Enum.map(events, fn event -> 
          ExMsg.NewEvent.new(
            event_id: Extreme.Tools.gen_uuid(),
            event_type: to_string(event.__struct__),
            data_content_type: 0,
            metadata_content_type: 0,
            data: :erlang.term_to_binary(event),
            meta: ""
          ) end)
        ExMsg.WriteEvents.new(
          event_stream_id: stream, 
          expected_version: -2,
          events: proto_events,
          require_master: false
        )
      end
  
  This way you can fine tune your requests, i.e. choose your serialization. We are using erlang serialization in this case
  `data: :erlang.term_to_binary(event)`, but you can do whatever suites you. 
  For more information about protobuf messages EventStore uses, 
  take a look at their [documentation](http://docs.geteventstore.com) or for common use cases 
  you can check `test/extreme_test.exs` file.
  """
  def execute(server, message), 
    do: GenServer.call(server, {:execute, message})


  @default_read_stream_events_opts [
    from_event_number: 0,
    max_count: 4096,
    resolve_link_tos: true,
    require_master: false,
  ]

  @doc """
  Returns a lazy `Stream` that will enumerate all of the events in `:stream`
  forwards starting with `:from_event_number`.

  `max_count` determines how many events are returned from any one read request
  made to the EventStore.

    opts = [
      max_count: 4096,
      resolve_link_tos: true,
      require_master: false,
    ]
  """
  def read_stream_events(server, stream, from_event_number, opts \\ []) do
    read_stream_events(server,
      @default_read_stream_events_opts
      |> Keyword.merge(opts)
      |> Keyword.put(:event_stream_id, stream)
      |> Keyword.put(:from_event_number, from_event_number)
    )
  end
  defp read_stream_events(server, opts) do
    Stream.unfold({server, opts, [], false},
      fn
        # The previously read page is empty. Read another page.
        {server, opts, [] = _page, false = _end_of_stream?} ->
          {:ok, %Extreme.Messages.ReadStreamEventsCompleted{} = read_response} =
            execute(server, Extreme.Messages.ReadStreamEvents.new(opts))
          [page_head|page_tail] = read_response.events
          next_from_event_number = read_response.next_event_number
          next_end_of_stream? = read_response.is_end_of_stream
          next_opts = Keyword.put(opts, :from_event_number, next_from_event_number)
          {page_head, {server, next_opts, page_tail, next_end_of_stream?}}

        # The page is empty and it was the last page of the stream. End the Stream.
        {_server, _opts, [] = _page, true = _end_of_stream?} ->
          nil

        # Return the next value from the previously read page.
        {server, opts, [page_head|page_tail], end_of_stream?} ->
          # IO.puts "returning from page"
          {page_head, {server, opts, page_tail, end_of_stream?}}

      end)
  end

  @doc """
  Reads events specified in `read_events`, sends them to `subscriber`
  and leaves `subscriber` subscribed per `subscribe` message.

  `subscriber` is process that will keep receiving {:on_event, event} messages.
  `read_events` :: Extreme.Messages.ReadStreamEvents
  `subscribe` :: Extreme.Messages.SubscribeToStream

  Returns {:ok, subscription} when subscription is success.
  If `stream` is hard deleted `subscriber` will receive message {:extreme, :error, :stream_hard_deleted, stream}
  If `stream` is soft deleted `subscriber` will receive message {:extreme, :warn, :stream_soft_deleted, stream}.

  In case of soft deleted stream, new event will recreate stream and it will be sent to `subscriber` as described above
  Hard deleted streams can't be recreated so suggestion is not to handle this message but rather crash when it happens

  ## Examples:

      defmodule MyApp.StreamSubscriber
        use GenServer
      
        def start_link(extreme, last_processed_event), 
          do: GenServer.start_link __MODULE__, {extreme, last_processed_event}
      
        def init({extreme, last_processed_event}) do
          stream = "people"
          state = %{ event_store: extreme, stream: stream, last_event: last_processed_event }
          GenServer.cast self(), :subscribe
          {:ok, state}
        end
      
        def handle_cast(:subscribe, state) do
          # read only unprocessed events and stay subscribed
          {:ok, subscription} = Extreme.read_and_stay_subscribed state.event_store, self(), state.stream, state.last_event + 1
          # we want to monitor when subscription is crashed so we can resubscribe
          ref = Process.monitor subscription
          {:noreply, %{state|subscription_ref: ref}}
        end
      
        def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
          GenServer.cast self(), :subscribe
          {:noreply, state}
        end
        def handle_info({:on_event, push}, state) do
          push.event.data
          |> :erlang.binary_to_term 
          |> process_event
          event_number = push.link.event_number
          :ok = update_last_event state.stream, event_number
          {:noreply, %{state|last_event: event_number}}
        end
        def handle_info(_msg, state), do: {:noreply, state}
      
        defp process_event(event), do: IO.puts("Do something with event: " <> inspect(event))

        defp update_last_event(_stream, _event_number), do: IO.puts("Persist last processed event_number for stream")
      end

  This way unprocessed events will be sent by Extreme, using `{:on_event, push}` message. 
  After all persisted messages are sent, new messages will be sent the same way as they arrive to stream.

  Since there's a lot of boilerplate code here, you can use `Extreme.Listener` to reduce it and focus only
  on business part of code.
  """
  def read_and_stay_subscribed(server, subscriber, stream, from_event_number \\ 0, per_page \\ 4096, resolve_link_tos \\ true, require_master \\ false) do
    GenServer.call(server, {:read_and_stay_subscribed, subscriber, {stream, from_event_number, per_page, resolve_link_tos, require_master}})
  end

  @doc """
  Subscribe `subscriber` to `stream` using `server`.

  `subscriber` is process that will keep receiving {:on_event, event} messages.

  Returns {:ok, subscription} when subscription is success.

  ```NOTE: If `stream` is hard deleted, `subscriber` will NOT receive any message!```

  ## Example:
      def subscribe(server, stream \\ "people"), do: Extreme.subscribe_to(server, self(), stream)
      
      def handle_info({:on_event, event}, state) do
        Logger.debug "New event added to stream 'people': " <> inspect(event)
        {:noreply, state}
      end

  As `Extreme.read_and_stay_subscribed/7` has it's abstraction in `Extreme.Listener`, there's abstraction for this function
  as well in `Extreme.FanoutListener` behaviour.
  """
  def subscribe_to(server, subscriber, stream, resolve_link_tos \\ true), 
    do: GenServer.call(server, {:subscribe_to, subscriber, stream, resolve_link_tos})


  ## Server Callbacks

  def init(connection_settings) do
    user = Keyword.fetch!(connection_settings, :username)
    pass = Keyword.fetch!(connection_settings, :password)
    GenServer.cast(self(), {:connect, connection_settings, 1})
    {:ok, sup} = Extreme.SubscriptionsSupervisor.start_link(self())
    {:ok, %{socket: nil, pending_responses: %{}, subscriptions: %{}, subscriptions_sup: sup, credentials: %{user: user, pass: pass}, received_data: <<>>, should_receive: nil}}
  end

  def handle_cast({:connect, connection_settings, attempt}, state) do
    db_type = Keyword.get(connection_settings, :db_type, :node)
    |> cast_to_atom
    case connect(db_type, connection_settings, attempt) do
      {:ok, socket} -> {:noreply, %{state|socket: socket}}
      error         -> {:stop, error, state}
    end
  end

  defp connect(:cluster, connection_settings, attempt) do
    {:ok, host, port} = Extreme.ClusterConnection.get_node(connection_settings)
    connect(host, port, connection_settings, attempt)
  end
  defp connect(:node, connection_settings, attempt) do
    host = Keyword.fetch!(connection_settings, :host)
    port = Keyword.fetch!(connection_settings, :port)
    connect(host, port, connection_settings, attempt)
  end
  defp connect(:cluster_dns, connection_settings, attempt) do
    {:ok, host, port} = Extreme.ClusterConnection.get_node(:cluster_dns, connection_settings)
    connect(host, port, connection_settings, attempt)
  end
  defp connect(host, port, connection_settings, attempt) do
    Logger.info "Connecting Extreme to #{host}:#{port}"
    opts = [:binary, active: :once]
    case :gen_tcp.connect(String.to_char_list(host), port, opts) do
      {:ok, socket} ->
        Logger.info "Successfuly connected to EventStore @ #{host}:#{port}"
        :timer.send_after(1_000, :send_ping)
        {:ok, socket}
      _             ->
        max_attempts = Keyword.get(connection_settings, :max_attempts, :infinity)
        reconnect = case max_attempts do
          :infinity -> true
          max when attempt <= max -> true
          _ -> false
        end
        if reconnect do
          reconnect_delay = Keyword.get connection_settings, :reconnect_delay, 1_000
          Logger.warn "Error connecting to EventStore @ #{host}:#{port}. Will retry in #{reconnect_delay} ms."
          :timer.sleep(reconnect_delay)
          db_type = Keyword.get(connection_settings, :db_type, :node)
          |> cast_to_atom
          connect(db_type, connection_settings, attempt + 1)
        else
          {:error, :max_attempt_exceeded}
        end
    end
  end

  def handle_call({:execute, protobuf_msg}, from, state) do
    {message, correlation_id} = Request.prepare(protobuf_msg, state.credentials)
    #Logger.debug "Will execute #{inspect protobuf_msg}"
    :ok = :gen_tcp.send(state.socket, message)
    state = put_in(state.pending_responses, Map.put(state.pending_responses, correlation_id, from))
    {:noreply, state}
  end
  def handle_call({:read_and_stay_subscribed, subscriber, params}, _from, state) do
    {:ok, subscription} = Extreme.SubscriptionsSupervisor.start_subscription(state.subscriptions_sup, subscriber, params)
    #Logger.debug "Subscription is: #{inspect subscription}"
    {:reply, {:ok, subscription}, state}
  end
  def handle_call({:subscribe_to, subscriber, stream, resolve_link_tos}, _from, state) do
    {:ok, subscription} = Extreme.SubscriptionsSupervisor.start_subscription(state.subscriptions_sup, subscriber, stream, resolve_link_tos)
    #Logger.debug "Subscription is: #{inspect subscription}"
    {:reply, {:ok, subscription}, state}
  end
  def handle_call({:subscribe, subscriber, msg}, from, state) do
    #Logger.debug "Subscribing #{inspect subscriber} with: #{inspect msg}"
    {message, correlation_id} = Request.prepare(msg, state.credentials)
    :ok = :gen_tcp.send(state.socket, message)
    state = put_in(state.pending_responses, Map.put(state.pending_responses, correlation_id, from))
    state = put_in(state.subscriptions,     Map.put(state.subscriptions, correlation_id, subscriber))
    {:noreply, state}
  end

  def handle_info(:send_ping, state) do
    message = Request.prepare(:ping)
    :ok = :gen_tcp.send(state.socket, message)
    {:noreply, state}
  end
  def handle_info({:tcp, socket, pkg}, state) do
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    state = process_package(pkg, state)
    {:noreply, state}
  end
  def handle_info({:tcp_closed, _port}, state), do: {:stop, :tcp_closed, state}


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
    state = process_message(message, %{state|should_receive: nil, received_data: <<>>})
    process_package(rest, state)
  end

  defp process_message(message, state) do
    #"Let's finally process whole message: #{inspect message}"
    Response.parse(message)
    |> respond(state)
  end

  defp respond({:pong, _correlation_id}, state) do
    #Logger.debug "#{inspect self()} got :pong"
    :timer.send_after 1_000, :send_ping
    state
  end
  defp respond({:heartbeat_request, correlation_id}, state) do
    #Logger.debug "#{inspect self()} Tick-Tack"
    message = Request.prepare(:heartbeat_response, correlation_id)
    :ok = :gen_tcp.send(state.socket, message)
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
        :ok = GenServer.reply(from, Response.reply(response))
        pending_responses = Map.delete(state.pending_responses, correlation_id)
        %{state|pending_responses: pending_responses}
    end
  end

  defp respond_to_subscription(response, correlation_id, subscriptions) do
    case Map.get(subscriptions, correlation_id) do
      nil          -> :ok #Logger.error "Can't find correlation_id #{inspect correlation_id} for response #{inspect response}"
      subscription -> GenServer.cast(subscription, Response.reply(response))
    end
  end

  @doc """
  Cast the provided value to an atom if appropriate.
  If the provided value is a string, convert it to an atom, otherwise return it as-is.
  """
  def cast_to_atom(value) when is_binary(value),
    do: String.to_atom(value)
  def cast_to_atom(value),
    do: value
end

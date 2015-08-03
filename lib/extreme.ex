defmodule Extreme do
  use GenServer
  alias Extreme.Request
  alias Extreme.Tools
  alias Extreme.Messages, as: Msg
  require Logger
  import Extreme.Response

  ## Client API

  @doc """
  Starts connection to EventStore using `connection_settings` and optional `opts`.
  """
  def start_link(connection_settings, opts \\[]) do
    host = Keyword.fetch! connection_settings, :host
    port = Keyword.fetch! connection_settings, :port
    user = Keyword.fetch! connection_settings, :username
    pass = Keyword.fetch! connection_settings, :password
    GenServer.start_link __MODULE__, {host, port, user, pass}, opts
  end

  @doc """
  Appends new `events` to `stream_id`. `expected_version` is defaulted to -2 (any). -1 stands for no stream.

  Returns {:ok, first_event_version, last_event_version} on success.
  Returns {:error, :not_authenticated} on wrong credentials.
  """
  def append(server, stream_id, expected_version \\ -2, events) do 
    protobuf_msg = Msg.WriteEvents.new(
      event_stream_id: stream_id, 
      expected_version: expected_version,
      events: translate_to_events(events),
      require_master: false
    )
    GenServer.call server, {:send, protobuf_msg}    
  end

  @doc """
  Reads single event from `stream_id` at given `event_number` position.

  Returns {:ok, expected_event} on success.
  Returns {:error, :not_found} when reading from non existing position in existing `stream_id`.
  """
  def read_event(server, stream_id, event_number, resolve_link_tos\\false) do
    protobuf_msg = Msg.ReadEvent.new(
        event_stream_id: stream_id,
        event_number: event_number,
        resolve_link_tos: resolve_link_tos,
        require_master: false
      )
    GenServer.call server, {:send, protobuf_msg}
  end

  @doc """
  Reads events from given `stream_id` from specified position `from_event_number` with given `batch_size` (which is by default is 4096 events). 
  It is possible to state if linked events should be resolved. By default linked events won't be resolved.

  Returns {:ok, events, last_event_id} on success, where events is list of {event_type, event_data}
  Returns {:error, :no_stream} if `stream_id` doesn't exist.
  """
  def read_stream_events_forward(server, stream_id, from_event_number, batch_size\\4096, resolve_link_tos\\false) do
    protobuf_msg = Msg.ReadStreamEvents.new(
        event_stream_id: stream_id,
        from_event_number: from_event_number,
        max_count: batch_size,
        resolve_link_tos: resolve_link_tos,
        require_master: false
      )
    GenServer.call server, {:send, protobuf_msg}
  end

  def delete_stream(server, stream_id, expected_version, hard_delete\\true) do
    protobuf_msg = Msg.DeleteStream.new(
        event_stream_id: stream_id,
        expected_version: expected_version,
        require_master: false,
        hard_delete: hard_delete
      )
    GenServer.call server, {:send, protobuf_msg}
  end

  defp translate_to_events(events) do
    Enum.map(events, fn {event_type, event} -> 
      Msg.NewEvent.new(
        event_id: Tools.gen_uuid(),
        event_type: event_type,
        data_content_type: 1,
        metadata_content_type: 1,
        data: event,
        meta: "{}"
      ) end)
  end

  ## Server Callbacks

  def init({host, port, user, pass}) do
    opts = [:binary, active: :once]
    {:ok, socket} = String.to_char_list(host)
                    |> :gen_tcp.connect(port, opts)
    {:ok, %{socket: socket, pending_responses: %{}, credentials: %{user: user, pass: pass}, received_data: <<>>, should_receive: nil}}
  end

  def handle_call({:send, protobuf_msg}, from, state) do
    {message, correlation_id} = Request.prepare protobuf_msg, state.credentials
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, <<message_length :: 32-unsigned-little-integer, rest :: binary>>=msg}, %{socket: socket, received_data: <<>>} = state) do
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    if message_length == byte_size(rest) + byte_size(state.received_data) do 
      process_message(msg, state)
    else
      {:noreply, %{state | received_data: msg, should_receive: message_length + 4}}
    end
  end
  def handle_info({:tcp, socket, msg}, state) do
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    if state.should_receive == byte_size(msg) + byte_size(state.received_data) do 
      process_message(state.received_data <> msg, state)
    else
      {:noreply, %{state | received_data: state.received_data <> msg}}
    end
  end

  defp process_message(msg, state) do
    msg
    |> Request.parse_response
    |> respond(state)
    {:noreply, %{state | received_data: <<>>, should_receive: nil}}
  end

  defp respond({:heartbeat_request, correlation_id}, state) do
    message = Request.prepare :heartbeat_response, correlation_id
    :ok = :gen_tcp.send state.socket, message
  end
  defp respond({:error, :not_authenticated, correlation_id}, state) do
    case Map.get(state.pending_responses, correlation_id) do
      nil -> 
        Logger.error "Can't find correlation_id #{correlation_id}"
        {:error, :correlation_id_not_found, correlation_id}
      from -> :ok = GenServer.reply(from, {:error, :not_authenticated})
    end
  end
  defp respond({_auth, correlation_id, response}, state) do
    case Map.get(state.pending_responses, correlation_id) do
      nil -> 
        Logger.error "Can't find correlation_id #{correlation_id} for response #{inspect response}"
        {:error, :correlation_id_not_found, correlation_id}
      from -> :ok = GenServer.reply(from, reply(response))
    end
  end

end

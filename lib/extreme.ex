defmodule Extreme do
  use GenServer
  alias Extreme.Request
  alias Extreme.Tools
  alias Extreme.Messages, as: Msg
  require Logger

  ## Client API

  @doc """
  Starts connection with EventStore `node` @ `host`:`port` with optional `opts`.
  """
  def start_link(_connection_type \\ :node, host \\ "localhost", port \\ 1113, opts \\[]) do
    GenServer.start_link __MODULE__, {host, port}, opts
  end

  @doc """
  Appends new `events` to `stream_id`. `expected_version` is defaulted to -2 (any). -1 stands for no stream.
  """
  def append(server, stream_id, expected_version \\ -2, events) do 
    protobuf_msg = Extreme.Messages.WriteEvents.new(
      event_stream_id: stream_id, 
      expected_version: expected_version,
      events: translate_to_events(events),
      require_master: false
    )
    GenServer.call server, {:send, protobuf_msg}    
  end

  defp translate_to_events(events) do
    Enum.map(events, fn e -> 
      data = Poison.encode!(e)
      Extreme.Messages.NewEvent.new(
        event_id: Tools.gen_uuid(),
        event_type: to_string(e.__struct__),
        data_content_type: 1,
        metadata_content_type: 1,
        data: data,
        meta: "{}"
      ) end)
  end

  ## Server Callbacks

  def init({host, port}) do
    opts = [:binary, active: :once]
    {:ok, socket} = String.to_char_list(host)
                    |> :gen_tcp.connect(port, opts)
    {:ok, %{socket: socket, pending_responses: %{}}}
  end

  def handle_call({:send, protobuf_msg}, from, state) do
    {message, correlation_id} = Request.prepare protobuf_msg
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    msg
    |> Request.parse_response
    |> respond(state.pending_responses)
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    {:noreply, state}
  end

  defp respond({auth, correlation_id, response}, pending_responses) do
    case Map.get(pending_responses, correlation_id) do
      nil -> Logger.error "Can't find correlation_id #{correlation_id} for response #{inspect response}"; :error
      from -> :ok = GenServer.reply(from, reply(response, auth))
    end
  end

  defp reply(%Msg.WriteEventsCompleted{}=data, _auth) do
    {data.result, data.first_event_number, data.last_event_number}
  end
  defp reply(1, _auth) do
    Logger.debug "HEARTBEAT"
  end
  defp reply(response, _auth) do
    Logger.error "Unhandled response: #{inspect response}"
    {:unhandled_response_type, response.__struct__}
  end
end

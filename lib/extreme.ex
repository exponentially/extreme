defmodule Extreme do
  use GenServer
  alias Extreme.Request
  alias Extreme.Tools

  ## Client API

  @doc """
  Starts connection with EventStore `node` @ `host`:`port` with optional `opts`.
  """
  def start_link(connection_type \\ :node, host \\ "localhost", port \\ 1113, opts \\[]) do
    GenServer.start_link __MODULE__, {host, port}, opts
  end

  def ping(server) do
    GenServer.call server, :ping
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
    res = Enum.map(events, fn e -> 
      data = Poison.encode!(e)
      Extreme.Messages.NewEvent.new(
        event_id: Tools.gen_uuid(),
        event_type: to_string(e.__struct__),
        data_content_type: 1,
        metadata_content_type: 1,
        data: data,
        meta: "{}"
      ) end)
    IO.puts inspect res
    res
  end

  #def command(server, command) do
  #  GenServer.call server, {:command, command}
  #end

  #@doc """
  #Reads all events from store
  #"""
  #def read_all_events(server, params \\ []) do
  #  msg = Extreme.Messages.ReadAllEvents.new commit_position: 0, 
  #  prepare_position: 0, max_count: 1000, resolve_link_tos: false, require_master: false 
  #  GenServer.call server, {:command, msg}
  #end

  ## Server Callbacks

  def init({host, port}) do
    opts = [:binary, active: :once]
    {:ok, socket} = String.to_char_list(host)
                    |> :gen_tcp.connect(port, opts)
    {:ok, %{socket: socket, pending_responses: %{}}}
  end

  #def handle_call(:ping, from, state) do
  #  data = <<1>>
  #  correlation_id = Tools.gen_uuid
  #  message = <<3, 0>> <> correlation_id <> data
  #  message_length = byte_size message
  #  IO.puts "#{inspect message_length}: #{inspect message}"
  #  state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
  #  :ok = :gen_tcp.send state.socket, <<message_length :: 32-unsigned-little-integer>> <> message
  #  {:noreply, state}
  #end

  def handle_call({:send, protobuf_msg}, from, state) do
    {message, correlation_id} = Request.prepare protobuf_msg
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end
  #def handle_call({:send, cmd, data}, from, state) do
  #  correlation_id = Tools.gen_uuid
  #  message = to_binary(cmd, correlation_id, {"admin", "changeit"}, data)
  #  size = byte_size(message)
  #  
  #  :ok = :gen_tcp.send state.socket, <<size::32-unsigned-little-integer>> <> message
  #  state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
  #  {:noreply, state}
  #end

  #def handle_call({:command, cmd}, from, state) do
  #  {message, correlation_id} = create_message cmd
  #  :ok = :gen_tcp.send state.socket, message
  #  state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
  #  {:noreply, state}
  #end

  #defp create_message(cmd) do
  #  correlation_id = gen_uuid
  #  message = cmd.__struct__.encode cmd
  #  {message, correlation_id}
  #end



  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    msg
    |> parse_response
    |> respond(state)  
    :inet.setopts(socket, active: :once) # Allow the socket to send us the next message
    {:noreply, state}
  end

  defp parse_response(<<message_length :: 32-unsigned-little-integer,
                        message_type,
                        auth,
                        correlation_id :: 16-binary,
                        data :: binary>>) do
    IO.puts "#{message_length} - #{message_type} (#{auth}) [#{inspect correlation_id}]: #{inspect data}"
    {message_type, auth, correlation_id, data}
  end

  defp respond({1, _auth, correlation_id, data}, state) do
    IO.puts "HEARTBEAT"
    #Pkg = erles_pkg:from_binary(Data),
    #case Pkg of
    #{pkg, heartbeat_req, CorrId, _Auth, PkgData} ->
    #  send_pkg(Socket, erles_pkg:create(heartbeat_resp, CorrId, PkgData));
  end

  defp respond({message_type, _auth, correlation_id, data}, state) do
    IO.puts inspect data
    #TODO: Figure out when to remove correlation_id from pending_responses
    case Map.get(state.pending_responses, correlation_id) do
      nil -> :error
      from -> :ok = GenServer.reply(from, decode(message_type, data))
    end
  end
    
  def decode(message_type, data) do
    IO.puts inspect data
    #decoded = Extreme.Messages.ReadAllEventsCompleted.decode msg
    #IO.puts inspect decoded
    #decoded
  end
end

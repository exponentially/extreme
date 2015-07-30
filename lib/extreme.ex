defmodule Extreme do
  use GenServer

  ## Client API

  @doc """
  Starts connection with EventStore @ `host`:`port` with optional `opts`.
  """
  def start_link(host \\ "localhost", port \\ 1113, opts \\[]) do
    GenServer.start_link __MODULE__, {host, port}, opts
  end

  def ping(server) do
    GenServer.call server, :ping
  end

  def append(server, stream_id, expected_version, events) do 
    write_events = Extreme.Messages.WriteEvents.new(
      event_stream_id: stream_id, 
      expected_version: expected_version,
      events: translate_to_events(events),
      require_master: false
    )
    message = Extreme.Messages.WriteEvents.encode(write_events)
    cmd = Extreme.MessageResolver.encode_cmd(:write_events)
    GenServer.call server, {:send, cmd, message}    
  end

  def translate_to_events(events) do
    res = Enum.map(events, fn e -> 
      data = Poison.encode!(e)
      Extreme.Messages.NewEvent.new(
        event_id: gen_uuid(),
        event_type: to_string(e.__struct__),
        data_content_type: 1,
        metadata_content_type: 1,
        data: data,
        meta: "{}"
      ) end)
    IO.puts inspect res
    res
  end

  def command(server, command) do
    GenServer.call server, {:command, command}
  end

  @doc """
  Reads all events from store
  """
  def read_all_events(server, params \\ []) do
    msg = Extreme.Messages.ReadAllEvents.new commit_position: 0, 
    prepare_position: 0, max_count: 1000, resolve_link_tos: false, require_master: false 
    GenServer.call server, {:command, msg}
  end

  ## Server Callbacks

  def init({host, port}) do
    opts = [:binary, active: :once]
    {:ok, socket} = String.to_char_list(host)
                    |> :gen_tcp.connect(port, opts)
    {:ok, %{socket: socket, pending_responses: %{}}}
  end

  def handle_call(:ping, from, state) do
    data = <<1>>
    correlation_id = gen_uuid
    message = <<3, 0>> <> correlation_id <> data
    message_length = byte_size message
    IO.puts "#{inspect message_length}: #{inspect message}"
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    :ok = :gen_tcp.send state.socket, <<message_length :: 32-unsigned-little-integer>> <> message
    {:noreply, state}
  end

  #defp parse_response(msg, state) do
  defp parse_response(<<message_length :: 32-unsigned-little-integer,
                        message_type,
                        auth,
                        correlation_id :: 16-binary,
                        data :: binary>>) do
    IO.puts "#{message_length} - #{message_type} (#{auth}) [#{inspect correlation_id}]: #{inspect data}"
    {message_type, auth, correlation_id, data}
  end

  def handle_call({:send, cmd, data}, from, state) do
    correlation_id = gen_uuid
    message = to_binary(cmd, correlation_id, {"admin", "changeit"}, data)
    size = byte_size(message)
    
    :ok = :gen_tcp.send state.socket, <<size::32-unsigned-little-integer>> <> message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end

  def to_binary(cmd, correlation_id, {login, password}, data) do
    login_len = byte_size(login)
    pass_len = byte_size(password)
    res = <<cmd, 1>> <> correlation_id <> <<login_len::size(8)>>
    res = res <> login <> <<pass_len::size(8)>> <> password <> data
  end

  def handle_call({:command, cmd}, from, state) do
    {message, correlation_id} = create_message cmd
    :ok = :gen_tcp.send state.socket, message
    state = put_in state.pending_responses, Map.put(state.pending_responses, correlation_id, from)
    {:noreply, state}
  end

  defp create_message(cmd) do
    correlation_id = gen_uuid
    message = cmd.__struct__.encode cmd
    {message, correlation_id}
  end

  defp gen_uuid do
    #<<rand1 :: size(48), _ :: size(4), rand2 :: size(12), _ :: size(2), rand3 :: size(62)>> = :crypto.rand_bytes(16)
    #res = <<rand1 :: size(48), 
    #0, 1, 0, 0,  # version 4 bits
    #rand2 :: size(12),
    #1, 0,            # RFC 4122 variant bits
    #rand3 :: size(62)>>
    #IO.inspect res
    #res
    #<<149, 114, 41, 78, 53, 250, 17, 229, 179, 123, 160, 211, 193, 157, 86, 216>>
    Keyword.get(UUID.info!(UUID.uuid1()), :binary, :undefined)
  end



  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    # Allow the socket to send us the next message
    :inet.setopts(socket, active: :once)
    a = parse_response msg
    respond(a, state)  
    
    {:noreply, state}
  end

  defp respond({1, _auth, _correlation_id, _data}, _state) do
    IO.puts "heartbeat"
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

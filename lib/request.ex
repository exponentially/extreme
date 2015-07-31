defmodule Extreme.Request do
  alias Extreme.Tools
  require Logger

  def prepare(protobuf_msg) do
    cmd = protobuf_msg.__struct__
    data = protobuf_msg.__struct__.encode protobuf_msg
    correlation_id = Tools.gen_uuid
    message = to_binary(cmd, correlation_id, {"admin", "changeit"}, data)

    {message, correlation_id}
  end

  def parse_response(<<message_length :: 32-unsigned-little-integer,
                        message_type,
                        auth,
                        correlation_id :: 16-binary,
                        data :: binary>>) do
    response_struct = Extreme.MessageResolver.decode_cmd message_type
    data = response_struct.decode data
    {auth, correlation_id, data}
  end

  defp to_binary(cmd, correlation_id, {login, password}, data) do
    login_len = byte_size(login)
    pass_len = byte_size(password)
    res = <<Extreme.MessageResolver.encode_cmd(cmd), 1>> <> 
          correlation_id <> 
          <<login_len::size(8)>>
    res = res <> login <> <<pass_len::size(8)>> <> password <> data
    size = byte_size(res)
    <<size::32-unsigned-little-integer>> <> res
  end
end

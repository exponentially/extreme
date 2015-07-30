defmodule Extreme.Request do
  alias Extreme.Tools

  def prepare(protobuf_msg) do
    cmd = protobuf_msg.__struct__
    data = protobuf_msg.__struct__.encode protobuf_msg
    correlation_id = Tools.gen_uuid
    message = to_binary(cmd, correlation_id, {"admin", "secret"}, data)

    {message, correlation_id}
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

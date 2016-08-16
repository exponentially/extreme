defmodule Extreme.MessageResolverNew.Test do
  use ExUnit.Case
  alias Extreme.MessageResolverNew

  def check(bit, el) do
    assert MessageResolverNew.decode_cmd(bit) == el
    assert MessageResolverNew.encode_cmd(el)  == bit
  end

  test "works" do
    check(1, :heartbeat_request_command)
    check(2, :heartbeat_response_command)
    Extreme.MessageCommandReader.tcp_commands
    |> Enum.each(fn({type, proto, bit})->
      case proto do
        false -> check(bit, type)
        _     -> check(bit, proto)
      end
    end)
  end
end

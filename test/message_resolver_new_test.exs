defmodule Extreme.MessageResolverNew.Test do
  use ExUnit.Case
  alias Extreme.MessageResolverNew

  def check(type, proto, bit) do
    cond do
      is_special?(type) -> check(type, proto, bit, :special)
      proto == false    -> check(type, bit)
      true              -> check(proto, bit)
    end
  end

  # decode to proto, encode from atom (type)
  def check(type, _proto, bit, :special) do
    assert MessageResolverNew.decode_cmd(bit) in [
      Extreme.Messages.ReadStreamEvents,
      Extreme.Messages.ReadStreamEventsCompleted,
      Extreme.Messages.ReadAllEvents,
      Extreme.Messages.ReadAllEventsCompleted
    ]

    assert MessageResolverNew.encode_cmd(type) == bit
  end
  def check(el, bit) do
    assert MessageResolverNew.decode_cmd(bit) == el
    assert MessageResolverNew.encode_cmd(el)  == bit
  end

  def is_special?(type) do
    Extreme.MessageCommandReader.special?(type)
  end

  test "works" do
    Extreme.MessageCommandReader.tcp_commands
    |> Enum.each(fn({type, proto, bit})->
      check(type, proto, bit)
    end)
  end
end

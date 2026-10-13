defmodule Extreme.ToolsTest do
  use ExUnit.Case
  import Extreme.Tools

  describe "cast_to_atom/1" do
    test "converts strings to atoms" do
      assert cast_to_atom("node") == :node
      assert cast_to_atom("cluster") == :cluster
      assert cast_to_atom("cluster_dns") == :cluster_dns
    end

    test "leaves atoms untouched" do
      assert cast_to_atom(:node) == :node
      assert cast_to_atom(:cluster) == :cluster
      assert cast_to_atom(:cluster_dns) == :cluster_dns
    end

    test "leaves other types untouched" do
      assert cast_to_atom(1) == 1
      assert cast_to_atom(2.0) == 2.0
      assert cast_to_atom(true) == true
      assert cast_to_atom(~c"hello world") == ~c"hello world"
    end
  end

  describe "generate_uuid/0" do
    test "returns a 16-byte UUIDv7 with the RFC 9562 variant" do
      assert <<_unix_ms::48, 7::4, _rand_a::12, 0b10::2, _rand_b::62>> = generate_uuid()
    end

    test "starts with the current unix time in milliseconds" do
      before = System.os_time(:millisecond)
      <<unix_ms::48, _rest::80>> = generate_uuid()

      assert unix_ms in before..System.os_time(:millisecond)
    end

    test "ids generated in later milliseconds sort after earlier ones" do
      ids =
        for _attempt <- 1..5 do
          id = generate_uuid()
          _wait_for_next_millisecond()
          id
        end

      assert ids == Enum.sort(ids)
      assert 5 == ids |> Enum.uniq() |> length()
    end

    test "a thousand ids in a row are unique" do
      assert 1_000 ==
               1..1_000 |> Enum.map(fn _n -> generate_uuid() end) |> Enum.uniq() |> length()
    end
  end

  defp _wait_for_next_millisecond do
    now = System.os_time(:millisecond)
    Process.sleep(1)
    if System.os_time(:millisecond) == now, do: _wait_for_next_millisecond()
  end
end

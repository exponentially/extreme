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
end

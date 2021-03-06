defmodule CastToAtomTest do
  use ExUnit.Case
  import Extreme, only: [cast_to_atom: 1]

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
    assert cast_to_atom('hello world') == 'hello world'
  end
end

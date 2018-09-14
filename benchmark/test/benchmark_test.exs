defmodule Extreme.BenchmarkTest do
  use ExUnit.Case
  doctest Extreme.Benchmark

  test "greets the world" do
    assert Extreme.Benchmark.hello() == :world
  end
end

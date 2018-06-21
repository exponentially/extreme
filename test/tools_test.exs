defmodule ToolsTest do
  use ExUnit.Case

  describe "normalize_port" do
    import Extreme.Tools, only: [normalize_port: 1]

    test "converts strings to integers" do
      assert normalize_port("1") == 1
    end

    test "leaves integers untouched" do
      assert normalize_port(1) == 1
    end

    test "leaves other types untouched" do
      assert normalize_port(:atom) == :atom
      assert normalize_port(true) == true
    end
  end
end

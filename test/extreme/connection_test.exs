defmodule Extreme.ConnectionTest do
  use ExUnit.Case, async: true
  alias Extreme.{Connection, Configuration}

  @test_configuration Application.get_env(:extreme, TestConn)

  describe "connect/3" do
    test "returns {:ok, socket} for correct host and port" do
      {:ok, host, port} = Configuration.get_node(@test_configuration)

      assert {:ok, _socket} = Connection.connect(host, port, [])
    end

    test "returns {:error, :max_attempt_exceeded} for incorrect port when `max_attempts` exceeds" do
      host = 'localhost'
      port = 1609

      assert {:error, :max_attempt_exceeded} = Connection.connect(host, port, max_attempts: 1)
    end
  end
end

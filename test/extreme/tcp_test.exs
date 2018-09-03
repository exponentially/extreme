defmodule Extreme.TcpTest do
  use ExUnit.Case, async: true
  alias Extreme.{Tcp, Configuration}

  @test_configuration Application.get_env(:extreme, :event_store)

  describe "connect/3" do
    test "returns {:ok, socket} for correct host and port" do
      host = Configuration.get_host(@test_configuration)
      port = Configuration.get_port(@test_configuration)

      assert {:ok, _socket} = Tcp.connect(host, port, [])
    end

    test "returns {:error, :max_attempt_exceeded} for incorrect port when `max_attempts` exceeds" do
      host = 'localhost'
      port = 1609

      assert {:error, :max_attempt_exceeded} = Tcp.connect(host, port, max_attempts: 1)
    end
  end
end

defmodule ExtremeTests.ConnTest do
  use ExUnit.Case

  setup do
    {:ok, conn_pid} = Extreme.Conn.start_link
    {:ok, conn: conn_pid}
  end

  test "It should connect to EventStore if :host connection is configured", %{conn: conn } do
    assert conn != nil
  end

  test "It should send binary data", %{conn: conn} do 
  	Extreme.Conn.send(conn, nil)
  end
end

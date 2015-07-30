defmodule ExtremeTest do
  use ExUnit.Case
  #doctest Extreme

  setup do
    {:ok, server} = Extreme.start_link #"10.10.13.4"
    {:ok, %{server: server}}
  end

  #test "reads all events" do
  #  Extreme.read_all_events server
  #end

  test "ping", %{server: server} do
    Extreme.ping server
  end
end

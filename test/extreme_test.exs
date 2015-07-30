defmodule ExtremeTest do
  use ExUnit.Case


  defmodule PersonCreated do
    defstruct [:name]
  end

  defmodule PersonChangedName do
    defstruct [:name]
  end

  setup do
    {:ok, server} = Extreme.start_link
    {:ok, %{server: server}}
  end

  #test "reads all events", %{server: server} do
  #  Extreme.read_all_events server
  #end

  # test "ping", %{server: server} do
  #   Extreme.ping server
  # end

  test "append", %{server: server} do 
    Extreme.append server, "people", [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]
  end
end

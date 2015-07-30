defmodule ExtremeTest do
  use ExUnit.Case
  #doctest Extreme


  defmodule PersonCreated do
    defstruct [:name]
  end

  defmodule PersonChangedName do
    defstruct [:name]
  end

  setup do
    {:ok, server} = Extreme.start_link "10.10.13.4"
    {:ok, %{server: server}}
  end

  #test "reads all events" do
  #  Extreme.read_all_events server
  #end

  # test "ping", %{server: server} do
  #   Extreme.ping server
  # end

  test "append", %{server: server} do 

    Extreme.append server, UUID.uuid1(), -1, [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]
  end
end

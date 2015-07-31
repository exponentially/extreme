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

  test ".append is success", %{server: server} do 
    assert {:Success, _, _} = Extreme.append server, "people", [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]
  end
end

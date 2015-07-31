defmodule ExtremeTest do
  use ExUnit.Case


  defmodule PersonCreated do
    defstruct [:name]
  end

  defmodule PersonChangedName do
    defstruct [:name]
  end

  setup do
    db_settings = Application.get_all_env :event_store
    {:ok, server} = Extreme.start_link db_settings
    {:ok, %{server: server}}
  end

  test ".append is not authenticated for wrong credentials" do 
    db_settings = Application.get_all_env(:event_store)
                  |> Keyword.put(:password, "wrong")
    {:ok, server} = Extreme.start_link db_settings

    assert {:error, :not_authenticated} = Extreme.append server, "people", []
  end

  test ".append is success", %{server: server} do 
    assert {:Success, _, _} = Extreme.append server, "people", [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]
  end
end

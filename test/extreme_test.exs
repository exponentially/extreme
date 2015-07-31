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

  test ".read_stream_events_forward is success", %{server: server} do
    test_stream_name = "people-reading_#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    
    Extreme.append server, test_stream_name, events
    {:Success, events_from_store, last_event_number} = Extreme.read_stream_events_forward server, test_stream_name, 0
    
    assert events == events_from_store
    assert last_event_number == 1
  end

  test ".read_event is success", %{server: server} do
    test_stream_name = "people-reading_#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    
    Extreme.append server, test_stream_name, events
    {:Success, event_from_store} = Extreme.read_event server, test_stream_name, 1
    
    assert [event_from_store] == tl(events)
  end
end

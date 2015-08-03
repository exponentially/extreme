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
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    
    Extreme.append server, test_stream_name, events
    assert {:Success, ^events, 1} = Extreme.read_stream_events_forward server, test_stream_name, 0
  end

  test  ".read_stream_events_forward is returning :NoStream atom if stream was never created", %{server: server} do
    assert {:NoStream, [], -1} = Extreme.read_stream_events_forward server, "non_existing_stream-#{UUID.uuid1}", 0
  end

  test ".read_stream_events_forward is success with empty list if events after specified position do not exist.", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    
    Extreme.append server, test_stream_name, events
    assert {:Success, [], 1} = Extreme.read_stream_events_forward server, test_stream_name, 2
  end

  test ".read_event is success", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    [expected_event] = tl(events)

    Extreme.append server, test_stream_name, events
    assert {:Success, ^expected_event} = Extreme.read_event server, test_stream_name, 1
  end

  test ".read_event is NotFound if reading from non existing poisting in existing stream.", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    
    Extreme.append server, test_stream_name, events
    assert {:NotFound, []} = Extreme.read_event server, test_stream_name, 2
  end
end

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
    events = [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}] 
    assert {:ok, _, _} = Extreme.append server, "people", Stream.map(events, &({to_string(&1.__struct__), :erlang.term_to_binary(&1)}))
  end

  test ".read_stream_events_forward is success even when response data is received in more tcp packages", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}]

    Extreme.append server, test_stream_name, Stream.map(events, &({to_string(&1.__struct__), :erlang.term_to_binary(&1)}))
    assert {:ok, stored_events, 18, true} = Extreme.read_stream_events_forward server, test_stream_name, 0
    assert events == Enum.map stored_events, fn {_event_type, event} -> :erlang.binary_to_term event end
  end

  test ".read_stream_events_forward is success with empty list if events after specified position do not exist.", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]

    Extreme.append server, test_stream_name, Stream.map(events, &({to_string(&1.__struct__), :erlang.term_to_binary(&1)}))
    assert {:ok, [], 1, true} = Extreme.read_stream_events_forward server, test_stream_name, 2
  end

  test ".read_stream_events_forward returns :no_stream for not existing stream", %{server: server} do
    {:error, :no_stream} = Extreme.read_stream_events_forward server, "non_existing", 0
  end

  test ".read_event is success", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    [expected_event] = tl(events)

    Extreme.append server, test_stream_name, Stream.map(events, &({to_string(&1.__struct__), :erlang.term_to_binary(&1)}))
    assert {:ok, _, stored_event} = Extreme.read_event server, test_stream_name, 1
    assert expected_event == :erlang.binary_to_term stored_event
  end

  test ".read_event is NotFound if reading from non existing poistion in existing stream.", %{server: server} do
    test_stream_name = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]

    Extreme.append server, test_stream_name, Stream.map(events, &({to_string(&1.__struct__), :erlang.term_to_binary(&1)}))
    assert {:error, :not_found} = Extreme.read_event server, test_stream_name, 2
  end
end

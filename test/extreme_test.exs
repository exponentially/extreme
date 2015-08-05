defmodule ExtremeTest do
  use ExUnit.Case
  alias Extreme.Messages, as: ExMsg

  defmodule PersonCreated, do: defstruct [:name]
  defmodule PersonChangedName, do: defstruct [:name]

  setup do
    {:ok, server} = Application.get_all_env(:event_store)
                    |> Extreme.start_link
    {:ok, server: server}
  end

  test ".execute is not authenticated for wrong credentials" do 
    {:ok, server} = Application.get_all_env(:event_store)
                    |> Keyword.put(:password, "wrong")
                    |> Extreme.start_link
    assert {:error, :not_authenticated} = Extreme.execute server, write_events
  end

  test "writing events is success", %{server: server} do 
    assert {:ok, _response} = Extreme.execute server, write_events
  end

  test "reading events is success even when response data is received in more tcp packages", %{server: server} do
    stream = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}]

    {:ok, _} = Extreme.execute server, write_events(stream, events)
    {:ok, response} = Extreme.execute server, read_events(stream)
    assert events == Enum.map response.events, fn event -> :erlang.binary_to_term event.event.data end
  end

  test "reading events from non existing stream returns :no_stream", %{server: server} do
    {:error, :NoStream, _es_response} = Extreme.execute server, read_events(to_string(UUID.uuid1))
  end

  test "reading single existing event is success", %{server: server} do
    stream = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    expected_event = List.last events

    {:ok, _} = Extreme.execute server, write_events(stream, events)
    assert {:ok, response} = Extreme.execute server, read_event(stream, 1)
    assert expected_event == :erlang.binary_to_term response.event.event.data
  end

  test "trying to read non existing event from existing stream returns :NotFound", %{server: server} do
    stream = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]
    expected_event = List.last events

    {:ok, _} = Extreme.execute server, write_events(stream, events)
    assert {:ok, response} = Extreme.execute server, read_event(stream, 1)
    assert expected_event == :erlang.binary_to_term response.event.event.data

    assert {:error, :NotFound, _read_event_completed} = Extreme.execute server, read_event(stream, 2)
  end

  defp write_events(stream \\ "people", events \\ [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]) do
    proto_events = Enum.map(events, fn event -> 
      ExMsg.NewEvent.new(
        event_id: Extreme.Tools.gen_uuid(),
        event_type: to_string(event.__struct__),
        data_content_type: 0,
        metadata_content_type: 0,
        data: :erlang.term_to_binary(event),
        meta: ""
      ) end)
    ExMsg.WriteEvents.new(
      event_stream_id: stream, 
      expected_version: -2,
      events: proto_events,
      require_master: false
    )
  end

  defp read_events(stream) do
    ExMsg.ReadStreamEvents.new(
      event_stream_id: stream,
      from_event_number: 0,
      max_count: 4096,
      resolve_link_tos: true,
      require_master: false
    )
  end

  defp read_event(stream, position) do
    ExMsg.ReadEvent.new(
      event_stream_id: stream,
      event_number: position,
      resolve_link_tos: true,
      require_master: false
    )
  end
end

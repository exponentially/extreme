defmodule ExtremeTest do
  use ExUnit.Case
  alias Extreme.Messages, as: ExMsg
  require Logger

  defmodule PersonCreated, do: defstruct [:name]
  defmodule PersonChangedName, do: defstruct [:name]

  setup do
    {:ok, server} = Application.get_env(:extreme, :event_store)
                    |> Extreme.start_link(name: Connection)
    {:ok, server: server}
  end

  test ".execute is not authenticated for wrong credentials" do 
    {:ok, server} = Application.get_env(:extreme, :event_store)
                    |> Keyword.put(:password, "wrong")
                    |> Extreme.start_link
    assert {:error, :not_authenticated} = Extreme.execute server, write_events
  end

  test "writing events is success", %{server: server} do 
    assert {:ok, response} = Extreme.execute server, write_events
    Logger.debug "Write response: #{inspect response}"
  end

  test "reading events is success even when response data is received in more tcp packages", %{server: server} do
    stream = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}, %PersonChangedName{name: "Reading Test"}]

    {:ok, _} = Extreme.execute server, write_events(stream, events)
    {:ok, response} = Extreme.execute server, read_events(stream)
    assert events == Enum.map response.events, fn event -> :erlang.binary_to_term event.event.data end
  end

  test "reading events from non existing stream returns :NoStream", %{server: server} do
    {:error, :NoStream, _es_response} = Extreme.execute server, read_events(to_string(UUID.uuid1))
  end

  defmodule Subscriber do
    use GenServer

    def start_link(sender) do
      GenServer.start_link __MODULE__, sender, name: __MODULE__
    end

    def received_events(server) do
      GenServer.call server, :received_events
    end

    def init(sender) do
      {:ok, %{sender: sender, received: []}}
    end

    def handle_info({:on_event, event}=message, state) do
      send state.sender, message
      {:noreply, %{state|received: [event|state.received]}}
    end

    def handle_call(:received_events, _from, state) do
      result = state.received
                |> Enum.reverse
                |> Enum.map(fn e -> 
        data = e.event.data
        :erlang.binary_to_term(data) 
                end)
      {:reply, result, state}
    end
  end

  test "read events and stay subscribed", %{server: server} do
    {:ok, server2} = Application.get_env(:extreme, :event_store)
                                  |> Extreme.start_link(name: SubscriptionConnection)
    Logger.debug "SELF: #{inspect self}"
    Logger.debug "Connection 1: #{inspect server}"
    Logger.debug "Connection 2: #{inspect server2}"
    stream = "domain-people-#{UUID.uuid1}"
    # prepopulate stream
    events1 = [%PersonCreated{name: "1"}, %PersonCreated{name: "2"}, %PersonCreated{name: "3"}]
    {:ok, _} = Extreme.execute server, write_events(stream, events1)

    # subscribe to existing stream
    {:ok, subscriber} = Subscriber.start_link self
    {:ok, _subscription} = Extreme.read_and_stay_subscribed server, subscriber, stream, 0, 2

    # assert first 3 events are received
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}

    # write two more after subscription
    events2 = [%PersonCreated{name: "4"}, %PersonCreated{name: "5"}, %PersonCreated{name: "6"}, %PersonCreated{name: "7"} , %PersonCreated{name: "8"}, %PersonCreated{name: "9"}, %PersonCreated{name: "10"}, %PersonCreated{name: "11"}, %PersonCreated{name: "12"}, %PersonCreated{name: "13"}, %PersonCreated{name: "14"}, %PersonCreated{name: "15"}, %PersonCreated{name: "16"}, %PersonCreated{name: "17"}, %PersonCreated{name: "18"}, %PersonCreated{name: "19"}, %PersonCreated{name: "20"}, %PersonCreated{name: "21"}, %PersonCreated{name: "22"}, %PersonCreated{name: "23"}, %PersonCreated{name: "24"}, %PersonCreated{name: "25"}, %PersonCreated{name: "26"}, %PersonCreated{name: "27"}]
    {:ok, _} = Extreme.execute server, write_events(stream, events2)

    # assert rest events have arrived as well
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}
    assert_receive {:on_event, _event}

    ## check if they came in correct order.
    assert Subscriber.received_events(subscriber) == events1 ++ events2

    {:ok, response} = Extreme.execute server, read_events(stream)
    assert events1 ++ events2 == Enum.map response.events, fn event -> :erlang.binary_to_term event.event.data end
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

  test "soft deleting stream can be done multiple times", %{server: server} do
    stream = "soft_deleted"
    events = [%PersonCreated{name: "Reading"}]
    {:ok, _} = Extreme.execute server, write_events(stream, events)
    assert {:ok, _response} = Extreme.execute server, read_events(stream)

    {:ok, _} = Extreme.execute server, delete_stream(stream)
    assert {:error, :NoStream, _es_response} = Extreme.execute server, read_events(stream)

    {:ok, _} = Extreme.execute server, write_events(stream, events)
    assert {:ok, _response} = Extreme.execute server, read_events(stream)
    {:ok, _} = Extreme.execute server, delete_stream(stream)
    assert {:error, :NoStream, _es_response} = Extreme.execute server, read_events(stream)
  end

  test "hard deleted stream can be done only once", %{server: server} do
    stream = "domain-people-#{UUID.uuid1}"
    events = [%PersonCreated{name: "Reading"}]
    {:ok, _} = Extreme.execute server, write_events(stream, events)
    assert {:ok, _response} = Extreme.execute server, read_events(stream)

    {:ok, _} = Extreme.execute server, delete_stream(stream, true)
    assert {:error, :StreamDeleted, _es_response} = Extreme.execute server, read_events(stream)
    {:error, :StreamDeleted, _} = Extreme.execute server, write_events(stream, events)
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

  defp delete_stream(stream, hard_delete \\ false) do
    ExMsg.DeleteStream.new(
      event_stream_id: stream,
      expected_version: -2,
      require_master: false,
      hard_delete: hard_delete
    )
  end
end

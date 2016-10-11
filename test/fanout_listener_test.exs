defmodule Extreme.FanoutListenerTest do
  use ExUnit.Case
  alias Extreme.Messages, as: ExMsg
  require Logger

  defmodule PersonCreated, do: defstruct [:name]
  defmodule PersonChangedName, do: defstruct [:name]

  defmodule MyListener do
    use Extreme.FanoutListener

    defp process_push(push) do
      send :test, {:processing_push, push.event.event_type, push.event.data}
      :ok
    end
  end

  setup do
    {:ok, server}    = Application.get_env(:extreme, :event_store)
                       |> Extreme.start_link
    Process.register self, :test
    {:ok, server: server}
  end

  test "Listener doesn't read events persisted before it is started", %{server: server} do
    Logger.debug "TEST: Listener doesn't read events persisted before it is started"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and don't expect it to read them
    {:ok, _listener} = MyListener.start_link(server, stream)
    refute_receive {:processing_push, event_type, event}
    refute_receive {:processing_push, event_type, event}
  end

  test "Listener doesnt read existing events but keeps listening for new ones", %{server: server} do
    Logger.debug "TEST: Listener doesn't read existing events but keeps listening for new ones"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and don't expect it to read them
    {:ok, _listener} = MyListener.start_link(server, stream)
    refute_receive {:processing_push, event_type, event}
    refute_receive {:processing_push, event_type, event}

    # write one more event to stream
    event3 = %PersonChangedName{name: "Laza"}
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event3])

    # expect that listener got new event
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.FanoutListenerTest.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)
  end

  defp write_events(stream, events) do
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
end

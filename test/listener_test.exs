defmodule Extreme.ListenerTest do
  use     ExUnit.Case, async: false
  alias   Extreme.Msg, as: ExMsg
  require Logger

  defmodule PersonCreated, do: defstruct [:name]
  defmodule PersonChangedName, do: defstruct [:name]

  defmodule DB do
    def start_link(name \\ :db, start_from \\ -1),
      do: Agent.start_link(fn -> %{start_from: start_from} end, name: name)

    def get_last_event(name \\ :db, listener, stream),
      do: Agent.get(name, fn state -> Map.get(state, {listener, stream}, state[:start_from]) end)

    def get_patch_range(name \\ :db, listener, stream),
      do: Agent.get(name, fn state -> Map.get(state, {listener, stream}) end)

    def start_patching(name \\ :db, listener, stream, from, until) do
      Agent.update(name, fn state -> Map.put(state, {listener, stream}, %{last_event: from, patch_until: until}) end)
      :ok
    end

    def patching_done(name \\ :db, listener, stream) do
      Agent.update(name, fn state -> Map.delete(state, {listener, stream}) end)
      :ok
    end

    def ack_event(name \\ :db, listener, stream, event_number),
      do: Agent.update(name, fn state -> Map.put(state, {listener, stream}, event_number) end)

    def in_transaction(fun), do: fun.()
  end

  defmodule MyListener do
    use   Extreme.Listener
    alias Extreme.ListenerTest.DB

    defp get_last_event(stream_name) do
      if patch_range = DB.get_patch_range(MyPatchedListener, stream_name) do
        {:patch, patch_range.last_event, patch_range.patch_until}
      else
        DB.get_last_event MyListener, stream_name
      end
    end

    def register_patching_start(stream_name, from_exclusive, until_inclusive),
      do: DB.start_patching MyPatchedListener, stream_name, from_exclusive, until_inclusive

    def patching_done(stream_name),
      do: DB.patching_done  MyPatchedListener, stream_name

    defp process_push(push, stream_name) do
      DB.in_transaction fn ->
        send :test, {:processing_push, push.event.event_type, push.event.data}
        DB.ack_event(MyListener, stream_name, push.event.event_number)
        Logger.debug "Processed event ##{push.event.event_number}"
        #for indexed stream we need to follow link event_number:
        #DB.ack_event(__MODULE__, stream_name, push.link.event_number)
      end
      #for indexed stream we need to return link event_number:
      #{:ok, push.link.event_number}
      {:ok, push.event.event_number}
    end

    def process_patch(push, stream_name) do
      DB.in_transaction fn ->
        send :test, {:processing_push_in_patch, push.event.event_type, push.event.data}
        DB.ack_event(MyPatchedListener, stream_name, push.event.event_number)
        Logger.debug "Patched event ##{push.event.event_number}"
        #for indexed stream we need to follow link event_number:
        #DB.ack_event(__MODULE__, stream_name, push.link.event_number)
      end
      #for indexed stream we need to return link event_number:
      #{:ok, push.link.event_number}
      {:ok, push.event.event_number}
    end
    # This override is optional
    def caught_up, do: Logger.debug("We are up to date. YEEEY!!!")
  end

  defmodule NewListener do
    use   Extreme.Listener
    alias Extreme.ListenerTest.DB

    defp get_last_event(stream_name) do
      DB.get_last_event :ignores_old_events_db, NewListener, stream_name
    end

    defp process_push(push, stream_name) do
      DB.in_transaction fn ->
        send :test, {:processing_push, push.event.event_type, push.event.data}
        DB.ack_event(:ignores_old_events_db, NewListener, stream_name, push.event.event_number)
        Logger.debug "Processed event ##{push.event.event_number}"
      end
      {:ok, push.event.event_number}
    end
  end

  setup do
    {:ok, server}    = Application.get_env(:extreme, :event_store)
                       |> Extreme.start_link
    :timer.sleep 10
    {:ok, _db}       = DB.start_link
    Process.register self(), :test
    {:ok, server: server}
  end

  test "Listener reads all events if never run before", %{server: server} do
    Logger.debug "TEST: Listener reads all events if never run before"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}
    assert DB.get_last_event(MyListener, stream) == -1

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and expect it to read them
    {:ok, _listener} = MyListener.start_link(server, stream)
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonCreated"
    assert event1 == :erlang.binary_to_term(event)
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event2 == :erlang.binary_to_term(event)
    assert DB.get_last_event(MyListener, stream) == 1
  end

  test "Listener reads existing unacked events", %{server: server} do
    Logger.debug "TEST: Listener reads existing unacked events"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])
    # fake that first event is already processed
    DB.ack_event(MyListener, stream, 0)
    assert DB.get_last_event(MyListener, stream) == 0

    # run listener and expect it to skip already processed events
    {:ok, _listener} = MyListener.start_link(server, stream)
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event2 == :erlang.binary_to_term(event)
    assert DB.get_last_event(MyListener, stream) == 1
  end

  test "Listener reads all events and keeps listening for new ones", %{server: server} do
    Logger.debug "TEST: Listener reads all events and keeps listening for new ones"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}
    assert DB.get_last_event(MyListener, stream) == -1

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and expect it to read them
    {:ok, _listener} = MyListener.start_link(server, stream)
    assert_receive {:processing_push, _, _}
    assert_receive {:processing_push, _, _}
    assert DB.get_last_event(MyListener, stream) == 1

    # write one more event to stream
    event3 = %PersonChangedName{name: "Laza"}
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event3])

    # expect that listener got new event
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)
    assert DB.get_last_event(MyListener, stream) == 2
  end

  test "Listener doesn't process previous events but keeps listening for new ones", %{server: server} do
    Logger.debug "TEST: Listener doesn't process previous events but keeps listening for new ones"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}
    {:ok, _db} = DB.start_link :ignores_old_events_db, :from_now
    assert DB.get_last_event(:ignores_old_events_db, NewListener, stream) == :from_now

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and expect it NOT to read them
    {:ok, _listener} = NewListener.start_link(server, stream)
    refute_receive {:processing_push, _, _}
    refute_receive {:processing_push, _, _}
    assert DB.get_last_event(:ignores_old_events_db, NewListener, stream) == :from_now

    # write one more event to stream
    event3 = %PersonChangedName{name: "Laza"}
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event3])

    # expect that listener got new event
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)
    assert DB.get_last_event(:ignores_old_events_db, NewListener, stream) == 2
  end

  test "Listener can be paused and resumed", %{server: server} do
    Logger.debug "TEST: Listener can be paused and resumed"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}
    assert DB.get_last_event(MyListener, stream) == -1

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])

    # run listener and expect it to read them
    {:ok, listener} = MyListener.start_link(server, stream)
    assert_receive {:processing_push, _, _}
    assert_receive {:processing_push, _, _}
    assert DB.get_last_event(MyListener, stream) == 1

    {:ok, last_event} = MyListener.pause listener
    assert last_event == 1

    # write one more event to stream
    event3 = %PersonChangedName{name: "Laza"}
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event3])

    # expect that listener didn't process new event
    refute_receive {:processing_push, _event_type, _event}

    # resume processing events
    :ok = MyListener.resume listener

    # expect that listener processed missed event
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)
    assert DB.get_last_event(MyListener, stream) == 2
  end

  test "Listener can pause processing, run patches retroactively and then resume listening", %{server: server} do
    Logger.debug "TEST: Listener can pause processing, run patches retroactively and then resume listening"
    stream = to_string(UUID.uuid1)
    event1 = %PersonCreated{name: "Pera Peric"}
    event2 = %PersonChangedName{name: "Zika"}
    assert DB.get_last_event(MyListener, stream) == -1

    # write 2 events to stream
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event1, event2])
    Logger.debug "Written 2 events"

    # run listener and expect it to process them
    {:ok, listener} = MyListener.start_link(server, stream)
    assert_receive {:processing_push, _, _}
    assert_receive {:processing_push, _, _}
    assert DB.get_last_event(MyListener, stream) == 1

    {:ok, last_event} = MyListener.patch listener
    assert last_event == 1

    # write one more event to stream
    event3 = %PersonChangedName{name: "Laza"}
    {:ok, %{result: :Success}} = Extreme.execute server, write_events(stream, [event3])
    Logger.debug "Written 1 event"

    # first two events are processed with PatchCallbacks module
    assert_receive {:processing_push_in_patch, event_type, _event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonCreated"
    assert_receive {:processing_push_in_patch, event_type, _event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"

    # event processing is resumed normally after patch is applied
    refute_receive {:processing_push_in_patch, _event_type, _event}
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.Extreme.ListenerTest.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)
    assert DB.get_last_event(MyListener, stream) == 2
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

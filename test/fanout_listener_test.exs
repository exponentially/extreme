defmodule Extreme.FanoutListenerTest do
  use ExUnit.Case, async: false
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  require Logger

  defmodule MyListener do
    use Extreme.FanoutListener

    defp process_push(push) do
      IO.puts(
        "pushing event ##{push.event.event_number} to test #{
          inspect(Process.whereis(:fanout_test))
        }"
      )

      send(:fanout_test, {:processing_push, push.event.event_type, push.event.data})
      :ok
    end
  end

  setup do
    true = Process.register(self(), :fanout_test)
    :ok
  end

  test "Listener doesn't read existing events but keeps listening for new ones" do
    stream = Helpers.random_stream_name()
    event1 = %Event.PersonCreated{name: "Pera"}
    event2 = %Event.PersonChangedName{name: "Zika"}
    event3 = %Event.PersonChangedName{name: "Laza"}

    # write 2 events to stream
    {:ok, _} = TestConn.execute(Helpers.write_events(stream, [event1, event2]))

    # run listener and don't expect it to read them
    {:ok, listener} = MyListener.start_link(TestConn, stream)
    refute_receive {:processing_push, _event_type, _event}
    refute_receive {:processing_push, _event_type, _event}

    # write one more event to stream
    {:ok, _} = TestConn.execute(Helpers.write_events(stream, [event3]))

    # expect that listener got new event
    assert_receive {:processing_push, event_type, event}
    assert event_type == "Elixir.ExtremeTest.Events.PersonChangedName"
    assert event3 == :erlang.binary_to_term(event)

    :ok = MyListener.unsubscribe(listener)
    Helpers.assert_no_leaks(TestConn)
  end

  test "Listener can resubscribe" do
    stream = Helpers.random_stream_name()
    {:ok, listener} = MyListener.start_link(TestConn, stream)

    event1 = %Event.PersonChangedName{name: "Laza"}
    event2 = %Event.PersonCreated{name: "Pera"}
    event3 = %Event.PersonChangedName{name: "Zika"}
    event4 = %Event.PersonChangedName{name: "Mika"}

    # write one event to stream
    {:ok, _} = TestConn.execute(Helpers.write_events(stream, [event1]))

    # expect that listener got new event
    assert_receive {:processing_push, _event_type, event}
    assert event1 == :erlang.binary_to_term(event)

    # Unsubscribe from further pushes
    :ok = MyListener.unsubscribe(listener)

    # write 2 events to stream
    {:ok, _} = TestConn.execute(Helpers.write_events(stream, [event2, event3]))

    refute_receive {:processing_push, _event_type, _event}
    refute_receive {:processing_push, _event_type, _event}

    # Resubscribe

    :ok = MyListener.resubscribe(listener)

    # write event to stream

    {:ok, _} = TestConn.execute(Helpers.write_events(stream, [event4]))

    # expect that listener got new event
    assert_receive {:processing_push, _event_type, event}
    assert event4 == :erlang.binary_to_term(event)

    :ok = MyListener.unsubscribe(listener)
    Helpers.assert_no_leaks(TestConn)
  end
end

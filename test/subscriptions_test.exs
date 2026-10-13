defmodule ExtremeSubscriptionsTest do
  use ExUnit.Case, async: false
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  alias Extreme.Messages, as: ExMsg
  require Logger

  describe "subscribe_to/3" do
    test "subscription to existing stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # :caught_up is not received on subscription without previous read
      refute_receive :caught_up

      # write more events after subscription
      num_additional_events = 1000

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "subscription to non existing stream is success" do
      # subscribe to stream
      stream = Helpers.random_stream_name()
      {:error, :no_stream, _} = TestConn.execute(Helpers.read_events(stream))
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "subscription to soft deleted stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      # soft delete stream
      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, false))

      {:error, :no_stream, %ExMsg.ReadStreamEventsCompleted{}} =
        TestConn.execute(Helpers.read_events(stream))

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two more events after subscription
      events2 = [%Event.PersonCreated{name: "4"}, %Event.PersonCreated{name: "5"}]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "soft deleting stream while subscription exists doesn't affect subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # soft delete stream
      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, false))

      assert {:error, :no_stream, %ExMsg.ReadStreamEventsCompleted{}} =
               TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # subscription is alive
      assert Process.alive?(subscription)
      assert Process.alive?(subscriber)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "hard deleting stream will close its subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # hard delete stream
      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, true))

      assert {:error, :stream_deleted, %ExMsg.ReadStreamEventsCompleted{}} =
               TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # ensure information of deleted stream is received
      assert_receive {:extreme, :stream_hard_deleted}
      # subscription is dead, but subscriber may survive
      assert Process.alive?(subscriber)
      :timer.sleep(10)
      refute Process.alive?(subscription)

      Helpers.assert_no_leaks(TestConn)
    end

    test "events are not pushed after unsubscribe" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # push events
      events1 =
        1..3
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      # ensure events are received
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # unsubscribe from stream
      Helpers.unsubscribe(TestConn, subscription)
      assert_receive {:extreme, :unsubscribed}

      # write more events after unsubscribe
      events2 =
        4..8
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are not received
      for _ <- 1..5, do: refute_receive({:on_event, _event})

      Helpers.assert_no_leaks(TestConn)
    end

    test "timeout for event processing can be adjusted" do
      sleep = 5_001
      # subscribe to stream
      stream = Helpers.random_stream_name()
      {:error, :no_stream, _} = TestConn.execute(Helpers.read_events(stream))
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber, true, sleep + 1_000)

      # write two events after subscription
      events = [%Event.SlowProcessingEventHappened{sleep: sleep}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      # assert rest events have arrived
      assert_receive {:on_event, _event}, sleep + 1_000
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      Helpers.unsubscribe(TestConn, subscription)
    end
  end

  describe "read_and_stay_subscribed/6" do
    test "read events and stay subscribed for existing stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are received
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "starting ahead of the stream's end catches up and pushes only live events from the start" do
      stream = Helpers.random_stream_name()
      [e0, e1, e2, e3, e4, e5, e6, e7] = for n <- 0..7, do: %Event.PersonCreated{name: "#{n}"}

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, [e0, e1, e2]))

      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 6, 2)
      _unsubscribe_on_exit(subscription)
      ref = Process.monitor(subscription)

      assert_receive :caught_up

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, [e3, e4, e5, e6, e7]))

      for _ <- 1..2, do: assert_receive({:on_event, _event})
      assert [e6, e7] == Subscriber.received_events(subscriber)
      refute_received {:DOWN, ^ref, :process, _subscription, _reason}

      Helpers.unsubscribe(TestConn, subscription)
    end

    for resolve_link_tos <- [true, false] do
      test "starting ahead of a category stream's end skips links below the start (resolve_link_tos: #{resolve_link_tos})" do
        category = "extremetest" <> String.replace(Helpers.uuid_string(), "-", "")
        category_stream = "$ce-" <> category

        {:ok, %ExMsg.WriteEventsCompleted{}} =
          TestConn.execute(Helpers.write_events(category <> "-one", _people(~w(0 1 2))))

        :ok = _wait_for_events(category_stream, 3)

        {:ok, subscriber} = Subscriber.start_link()

        {:ok, subscription} =
          TestConn.read_and_stay_subscribed(
            category_stream,
            subscriber,
            5,
            2,
            unquote(resolve_link_tos)
          )

        _unsubscribe_on_exit(subscription)
        assert_receive :caught_up

        {:ok, %ExMsg.WriteEventsCompleted{}} =
          TestConn.execute(Helpers.write_events(category <> "-two", _people(~w(3 4 5 6))))

        assert_receive {:on_event, first}
        assert_receive {:on_event, second}
        assert [5, 6] == Enum.map([first, second], &_link_number/1)

        Helpers.unsubscribe(TestConn, subscription)
      end
    end

    test "rejects per_page 0 at the call" do
      {:ok, subscriber} = Subscriber.start_link()

      assert %FunctionClauseError{module: TestConn, function: :read_and_stay_subscribed} =
               assert_raise(FunctionClauseError, fn ->
                 TestConn.read_and_stay_subscribed(Helpers.random_stream_name(), subscriber, 0, 0)
               end)
    end

    test "rejects a negative start at the call" do
      {:ok, subscriber} = Subscriber.start_link()

      assert %FunctionClauseError{module: TestConn, function: :read_and_stay_subscribed} =
               assert_raise(FunctionClauseError, fn ->
                 TestConn.read_and_stay_subscribed(
                   Helpers.random_stream_name(),
                   subscriber,
                   -1,
                   2
                 )
               end)
    end

    test "RequestManager rejects per_page outside 1..4096 and a negative start for callers bypassing the public guard" do
      stream = Helpers.random_stream_name()

      for {from, per_page} <- [{0, 0}, {0, 4097}, {-1, 2}] do
        assert_raise FunctionClauseError, fn ->
          Extreme.RequestManager.read_and_stay_subscribed(
            TestConn,
            self(),
            {stream, from, per_page, true, false, 5_000}
          )
        end
      end
    end

    test "read events and stay subscribed for non existing stream is ok" do
      stream = Helpers.random_stream_name()

      {:error, :no_stream, %ExMsg.ReadStreamEventsCompleted{}} =
        TestConn.execute(Helpers.read_events(stream))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 20)

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for soft deleted stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, false))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are receiveD
      for _ <- 1..3, do: refute_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      assert_receive {:extreme, :warn, :stream_soft_deleted, ^stream}
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "unsubscribing while the read of a soft-deleted stream is retried stops it cleanly" do
      stream = Helpers.random_stream_name()

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, _people(~w(1))))

      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, false))

      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 3)
      ref = Process.monitor(subscription)

      :ok = TestConn.unsubscribe(subscription)

      assert_receive {:DOWN, ^ref, :process, _subscription, {:shutdown, :unsubscribed}}
      refute_received :caught_up
    end

    test "read events and stay subscribed for recreated stream is ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      events2 = [
        %Event.PersonCreated{name: "4"},
        %Event.PersonCreated{name: "5"},
        %Event.PersonCreated{name: "6"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, false))

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 3)

      # assert first events are receiveD
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      refute_receive {:extreme, :warn, :stream_soft_deleted, ^stream}
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events3 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x + 6}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events3))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2 ++ events3

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events2 ++ events3 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "read events and stay subscribed for hard deleted stream is not ok" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      {:ok, %ExMsg.DeleteStreamCompleted{}} =
        TestConn.execute(Helpers.delete_stream(stream, true))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert :caught_up is received when existing events are read
      assert_receive {:extreme, :error, :stream_deleted, ^stream}

      # wait a bit for process to die
      :timer.sleep(10)
      refute Process.alive?(subscription)
      Helpers.assert_no_leaks(TestConn)
    end

    test "events written while subscribing are also pushed to client in correct order" do
      stream = Helpers.random_stream_name()
      num_events = 200
      # prepopulate stream
      events1 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      events2 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x + num_events}"} end)

      Enum.each(events1, fn e ->
        {:ok, %ExMsg.WriteEventsCompleted{}} = TestConn.execute(Helpers.write_events(stream, [e]))
      end)

      # bombard the stream with individual event writes in the background
      spawn(fn ->
        Enum.each(events2, fn e ->
          {:ok, %ExMsg.WriteEventsCompleted{}} =
            TestConn.execute(Helpers.write_events(stream, [e]))
        end)

        Logger.debug("Second pack of events written")
      end)

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are received
      for _ <- 1..num_events, do: assert_receive({:on_event, _event})

      Logger.debug("First pack of events received")

      # assert second pack of events is received as well
      for _ <- 1..num_events, do: assert_receive({:on_event, _event})
      Logger.debug("Second pack of events received")

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 2_000))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "events written just after subscription starts are also pushed to client in correct order" do
      stream = Helpers.random_stream_name()
      num_events = 200
      # prepopulate stream
      events1 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      events2 =
        1..num_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x + num_events}"} end)

      Enum.each(events1, fn e ->
        {:ok, %ExMsg.WriteEventsCompleted{}} = TestConn.execute(Helpers.write_events(stream, [e]))
      end)

      spawn(fn ->
        Enum.each(events2, fn e ->
          {:ok, %ExMsg.WriteEventsCompleted{}} =
            TestConn.execute(Helpers.write_events(stream, [e]))
        end)

        Logger.debug("Second pack of events written")
      end)

      Process.sleep(100)

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()

      # TODO make it more likely or guaranteed that the race would fail

      {:ok, subscription} = TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2)

      # assert first events are received
      for _ <- 1..num_events, do: assert_receive({:on_event, _event})

      Logger.debug("First pack of events received")

      # assert second pack of events is received as well
      for _ <- 1..num_events, do: assert_receive({:on_event, _event})
      Logger.debug("Second pack of events received")

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 2_000))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end

    test "ack timeout can be adjusted" do
      sleep = 5_001
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.SlowProcessingEventHappened{sleep: sleep},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link()

      {:ok, subscription} =
        TestConn.read_and_stay_subscribed(stream, subscriber, 0, 2, true, false, sleep + 10)

      # assert first events are received
      for _ <- 1..3, do: assert_receive({:on_event, _event})

      # assert :caught_up is received when existing events are read
      assert_receive :caught_up

      # write more events after subscription
      num_additional_events = 100

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, %ExMsg.WriteEventsCompleted{}} =
        TestConn.execute(Helpers.write_events(stream, events2))

      # assert new events are received as well
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events1 ++ events2

      {:ok, %ExMsg.ReadStreamEventsCompleted{} = response} =
        TestConn.execute(Helpers.read_events(stream, 0, 200))

      assert events1 ++ events2 ==
               Enum.map(response.events, fn event -> :erlang.binary_to_term(event.event.data) end)

      Helpers.unsubscribe(TestConn, subscription)
    end
  end

  defp _people(names), do: for(name <- names, do: %Event.PersonCreated{name: name})

  # The category projection writes links asynchronously.
  defp _wait_for_events(stream, count, attempts \\ 50)

  defp _wait_for_events(_stream, _count, 0),
    do: flunk("category projection not running? start ESDB with standard projections")

  defp _wait_for_events(stream, count, attempts) do
    stream
    |> Helpers.read_events(0, 100)
    |> TestConn.execute()
    |> case do
      {:ok, %ExMsg.ReadStreamEventsCompleted{events: events}} when length(events) >= count ->
        :ok

      _not_yet ->
        Process.sleep(100)
        _wait_for_events(stream, count, attempts - 1)
    end
  end

  defp _unsubscribe_on_exit(subscription) do
    on_exit(fn ->
      ref = Process.monitor(subscription)
      :ok = TestConn.unsubscribe(subscription)

      receive do
        {:DOWN, ^ref, :process, _subscription, _reason} -> :ok
      after
        5_000 -> :ok
      end
    end)
  end

  defp _link_number(%ExMsg.ResolvedEvent{link: %ExMsg.EventRecord{event_number: number}}),
    do: number

  defp _link_number(%ExMsg.ResolvedEvent{event: %ExMsg.EventRecord{event_number: number}}),
    do: number
end

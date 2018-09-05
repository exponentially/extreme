defmodule ExtremeSubscriptionsTest do
  use ExUnit.Case, async: false
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  require Logger

  defmodule Subscriber do
    use GenServer

    def start_link(sender),
      do: GenServer.start_link(__MODULE__, sender)

    def received_events(server),
      do: GenServer.call(server, :received_events)

    @impl true
    def init(sender),
      do: {:ok, %{sender: sender, received: []}}

    @impl true
    def handle_call(:received_events, _from, state) do
      result =
        state.received
        |> Enum.reverse()
        |> Enum.map(fn e ->
          data = e.event.data
          :erlang.binary_to_term(data)
        end)

      {:reply, result, state}
    end

    @impl true
    def handle_info({:on_event, event} = message, state) do
      send(state.sender, message)
      {:noreply, %{state | received: [event | state.received]}}
    end

    def handle_info({:on_event, event, _correlation_id} = message, state) do
      send(state.sender, message)
      {:noreply, %{state | received: [event | state.received]}}
    end

    def handle_info({:extreme, _, problem, stream} = message, state) do
      Logger.warn("Stream #{stream} issue: #{to_string(problem)}")
      send(state.sender, message)
      {:noreply, state}
    end

    def handle_info({:extreme, :stream_deleted} = message, state) do
      send(state.sender, message)
      {:noreply, state}
    end

    def handle_info(:caught_up, state) do
      send(state.sender, :caught_up)
      {:noreply, state}
    end
  end

  describe "subscribe_to/3" do
    test "subscription to existing stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # subscribe to existing stream
      {:ok, subscriber} = Subscriber.start_link(self())
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # :caught_up is not received on subscription without previous read
      refute_receive :caught_up

      # write more events after subscription
      num_additional_events = 1000

      events2 =
        1..num_additional_events
        |> Enum.map(fn x -> %Event.PersonCreated{name: "Name #{x}"} end)

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      for _ <- 1..num_additional_events, do: assert_receive({:on_event, _event})

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      _unsubscribe(subscription)
    end

    test "subscription to non existing stream is success" do
      # subscribe to stream
      stream = Helpers.random_stream_name()
      {:warn, :empty_stream} = TestConn.execute(Helpers.read_events(stream))
      {:ok, subscriber} = Subscriber.start_link(self())
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events

      _unsubscribe(subscription)
    end

    test "subscription to soft deleted stream is success" do
      stream = Helpers.random_stream_name()
      # prepopulate stream
      events1 = [
        %Event.PersonCreated{name: "1"},
        %Event.PersonCreated{name: "2"},
        %Event.PersonCreated{name: "3"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events1))

      # soft delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      {:error, :stream_deleted} = TestConn.execute(Helpers.read_events(stream))

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link(self())
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two more events after subscription
      events2 = [%Event.PersonCreated{name: "4"}, %Event.PersonCreated{name: "5"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert rest events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # check if only new events came in correct order.
      assert Subscriber.received_events(subscriber) == events2

      _unsubscribe(subscription)
    end

    test "soft deleting stream while subscription exists doesn't affect subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link(self())
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # soft delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      assert {:error, :stream_deleted} = TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # subscription is alive
      assert Process.alive?(subscription)
      assert Process.alive?(subscriber)

      _unsubscribe(subscription)
    end

    test "hard deleting stream will close its subscription" do
      stream = Helpers.random_stream_name()

      # subscribe to stream
      {:ok, subscriber} = Subscriber.start_link(self())
      {:ok, subscription} = TestConn.subscribe_to(stream, subscriber)

      # write two events after subscription
      events2 = [%Event.PersonCreated{name: "1"}, %Event.PersonCreated{name: "2"}]
      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events2))

      # assert events have arrived
      assert_receive {:on_event, _event}
      assert_receive {:on_event, _event}

      # hard delete stream
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, true))
      assert {:error, :stream_deleted} = TestConn.execute(Helpers.read_events(stream))

      # check if events came in correct order.
      assert Subscriber.received_events(subscriber) == events2
      # ensure information of deleted stream is received
      assert_receive {:extreme, :stream_deleted}
      # subscription is dead, but subscriber may survive
      assert Process.alive?(subscriber)
      :timer.sleep(10)
      refute Process.alive?(subscription)

      Helpers.assert_no_leaks(TestConn)
    end
  end

  defp _unsubscribe(subscription) do
    :unsubscribed = TestConn.unsubscribe(subscription)
    Helpers.assert_no_leaks(TestConn)
  end
end

defmodule ExtremeTest do
  use ExUnit.Case, async: true
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  alias Extreme.Messages, as: ExMsg

  defmodule TestConn do
    use Extreme, config: Application.get_env(:extreme, :event_store)
  end

  setup_all do
    {:ok, _} = TestConn.start_link()
    :ok
  end

  describe "start_link/2" do
    test "accepts configuration and makes connection" do
      assert ExtremeTest.TestConn
             |> Extreme.RequestManager._name()
             |> Process.whereis()
             |> Process.alive?()
    end
  end

  describe "Authentication" do
    defmodule ForbiddenConn do
      use Extreme
    end

    test ".execute is not authenticated for wrong credentials" do
      {:ok, _} =
        Helpers.test_configuration()
        |> Keyword.put(:password, "wrong")
        |> ForbiddenConn.start_link()

      assert {:error, :not_authenticated} = ForbiddenConn.execute(Helpers.write_events())
    end
  end

  describe "Writing events" do
    test "for non existing stream is success" do
      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 0,
                last_event_number: 1
              }} = TestConn.execute(Helpers.write_events())
    end

    test "for existing stream is success" do
      stream = Helpers.random_stream_name()

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 0,
                last_event_number: 1
              }} = TestConn.execute(Helpers.write_events(stream))

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 2,
                last_event_number: 3
              }} = TestConn.execute(Helpers.write_events(stream))
    end

    test "for soft deleted stream is success" do
      stream = Helpers.random_stream_name()

      assert {:ok, %ExMsg.WriteEventsCompleted{}} = TestConn.execute(Helpers.write_events(stream))

      assert {:ok, %Extreme.Messages.DeleteStreamCompleted{}} =
               TestConn.execute(Helpers.delete_stream(stream, false))

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 2,
                last_event_number: 3
              }} = TestConn.execute(Helpers.write_events(stream))
    end

    test "for hard deleted stream is refused" do
      stream = Helpers.random_stream_name()

      assert {:ok, %ExMsg.WriteEventsCompleted{}} = TestConn.execute(Helpers.write_events(stream))

      assert {:ok, %Extreme.Messages.DeleteStreamCompleted{}} =
               TestConn.execute(Helpers.delete_stream(stream, true))

      assert {:error, :stream_deleted} = TestConn.execute(Helpers.write_events(stream))
    end
  end

  describe "Reading events" do
    test "is success when response data is received in more tcp packages" do
      stream = Helpers.random_stream_name()

      events = [
        %Event.PersonCreated{name: "Reading"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"},
        %Event.PersonChangedName{name: "Reading Test"}
      ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      {:ok, %ExMsg.ReadStreamEventsCompleted{events: read_events}} =
        TestConn.execute(Helpers.read_events(stream, 0, 20))

      assert events ==
               Enum.map(read_events, fn event -> :erlang.binary_to_term(event.event.data) end)
    end

    test "from non existing stream returns {:warn, :empty_stream}" do
      {:warn, :empty_stream} = TestConn.execute(Helpers.read_events(Helpers.random_stream_name()))
    end

    test "from soft deleted stream returns {:error, :stream_deleted}" do
      stream = Helpers.random_stream_name()
      {:ok, _} = TestConn.execute(Helpers.write_events(stream))
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      {:error, :stream_deleted} = TestConn.execute(Helpers.read_events(stream))
    end

    test "from hard deleted stream returns {:error, :stream_deleted}" do
      stream = Helpers.random_stream_name()
      {:ok, _} = TestConn.execute(Helpers.write_events(stream))
      {:ok, _} = TestConn.execute(Helpers.delete_stream(stream, false))
      {:error, :stream_deleted} = TestConn.execute(Helpers.read_events(stream))
    end

    test "backward is success" do
      stream = Helpers.random_stream_name()

      events =
        [event1, event2] = [
          %Event.PersonCreated{name: "Reading"},
          %Event.PersonChangedName{name: "Reading Test"}
        ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))
      {:ok, response} = TestConn.execute(Helpers.read_events_backward(stream, -1, 100))

      assert %{is_end_of_stream: true, last_event_number: 1, next_event_number: -1} = response
      assert [ev2, ev1] = response.events
      assert event2 == :erlang.binary_to_term(ev2.event.data)
      assert event1 == :erlang.binary_to_term(ev1.event.data)
      assert ev2.event.event_number == 1
      assert ev1.event.event_number == 0
    end

    test "backwards can give last event" do
      stream = Helpers.random_stream_name()

      events =
        [_, event2] = [
          %Event.PersonCreated{name: "Reading"},
          %Event.PersonChangedName{name: "Reading Test"}
        ]

      {:ok, _} = TestConn.execute(Helpers.write_events(stream, events))

      assert {:ok, response} = TestConn.execute(Helpers.read_events_backward(stream, -1, 1))

      assert %{is_end_of_stream: false, last_event_number: 1, next_event_number: 0} = response
      assert [ev2] = response.events
      assert event2 == :erlang.binary_to_term(ev2.event.data)
      assert ev2.event.event_number == 1
    end
  end
end

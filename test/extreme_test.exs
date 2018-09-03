defmodule ExtremeTest do
  use ExUnit.Case, async: true
  alias Extreme.Messages, as: ExMsg
  require Logger

  defmodule(PersonCreated, do: defstruct([:name]))
  defmodule(PersonChangedName, do: defstruct([:name]))

  @base_name ExtremeTest

  setup_all do
    {:ok, _} = Extreme.start_link(@base_name, _test_configuration())
    :ok
  end

  describe "start_link/2" do
    test "accepts configuration and makes connection" do
      assert @base_name
             |> Extreme.RequestManager._name()
             |> Process.whereis()
             |> Process.alive?()
    end
  end

  describe "Authentication" do
    test ".execute is not authenticated for wrong credentials" do
      config =
        _test_configuration()
        |> Keyword.put(:password, "wrong")

      {:ok, _} = Extreme.start_link(Forbidden, config)

      assert {:error, :not_authenticated} = Extreme.execute(Forbidden, _write_events())
    end
  end

  describe "Writing events" do
    test "for non existing stream is success" do
      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 0,
                last_event_number: 1
              }} = Extreme.execute(@base_name, _write_events())
    end

    test "for existing stream is success" do
      stream = _random_stream_name()

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 0,
                last_event_number: 1
              }} = Extreme.execute(@base_name, _write_events(stream))

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 2,
                last_event_number: 3
              }} = Extreme.execute(@base_name, _write_events(stream))
    end

    test "for soft deleted stream is success" do
      stream = _random_stream_name()

      assert {:ok, %ExMsg.WriteEventsCompleted{}} =
               Extreme.execute(@base_name, _write_events(stream))

      assert {:ok, %Extreme.Messages.DeleteStreamCompleted{}} =
               Extreme.execute(@base_name, _delete_stream(stream, false))

      assert {:ok,
              %ExMsg.WriteEventsCompleted{
                current_version: 0,
                first_event_number: 2,
                last_event_number: 3
              }} = Extreme.execute(@base_name, _write_events(stream))
    end

    test "for hard deleted stream is refused" do
      stream = _random_stream_name()

      assert {:ok, %ExMsg.WriteEventsCompleted{}} =
               Extreme.execute(@base_name, _write_events(stream))

      assert {:ok, %Extreme.Messages.DeleteStreamCompleted{}} =
               Extreme.execute(@base_name, _delete_stream(stream, true))

      assert {:error, :stream_deleted} = Extreme.execute(@base_name, _write_events(stream))
    end
  end

  describe "Reading events" do
    test "is success when response data is received in more tcp packages" do
      stream = _random_stream_name()

      events = [
        %PersonCreated{name: "Reading"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"},
        %PersonChangedName{name: "Reading Test"}
      ]

      {:ok, _} = Extreme.execute(@base_name, _write_events(stream, events))

      {:ok, %ExMsg.ReadStreamEventsCompleted{events: read_events}} =
        Extreme.execute(@base_name, _read_events(stream, 0, 20))

      assert events ==
               Enum.map(read_events, fn event -> :erlang.binary_to_term(event.event.data) end)
    end

    test "from non existing stream returns {:warn, :empty_stream}" do
      {:warn, :empty_stream} = Extreme.execute(@base_name, _read_events(_random_stream_name()))
    end

    test "from soft deleted stream returns {:error, :stream_deleted}" do
      stream = _random_stream_name()
      {:ok, _} = Extreme.execute(@base_name, _write_events(stream))
      {:ok, _} = Extreme.execute(@base_name, _delete_stream(stream, false))
      {:error, :stream_deleted} = Extreme.execute(@base_name, _read_events(stream))
    end

    test "from hard deleted stream returns {:error, :stream_deleted}" do
      stream = _random_stream_name()
      {:ok, _} = Extreme.execute(@base_name, _write_events(stream))
      {:ok, _} = Extreme.execute(@base_name, _delete_stream(stream, false))
      {:error, :stream_deleted} = Extreme.execute(@base_name, _read_events(stream))
    end

    test "backward is success" do
      stream = _random_stream_name()

      events =
        [event1, event2] = [
          %PersonCreated{name: "Reading"},
          %PersonChangedName{name: "Reading Test"}
        ]

      {:ok, _} = Extreme.execute(@base_name, _write_events(stream, events))
      {:ok, response} = Extreme.execute(@base_name, _read_events_backward(stream, -1, 100))

      assert %{is_end_of_stream: true, last_event_number: 1, next_event_number: -1} = response
      assert [ev2, ev1] = response.events
      assert event2 == :erlang.binary_to_term(ev2.event.data)
      assert event1 == :erlang.binary_to_term(ev1.event.data)
      assert ev2.event.event_number == 1
      assert ev1.event.event_number == 0
    end

    test "backwards can give last event" do
      stream = _random_stream_name()

      events =
        [_, event2] = [%PersonCreated{name: "Reading"}, %PersonChangedName{name: "Reading Test"}]

      {:ok, _} = Extreme.execute(@base_name, _write_events(stream, events))
      assert {:ok, response} = Extreme.execute(@base_name, _read_events_backward(stream, -1, 1))

      assert %{is_end_of_stream: false, last_event_number: 1, next_event_number: 0} = response
      assert [ev2] = response.events
      assert event2 == :erlang.binary_to_term(ev2.event.data)
      assert ev2.event.event_number == 1
    end
  end

  defp _test_configuration,
    do: Application.get_env(:extreme, :event_store)

  defp _random_stream_name, do: "extreme_test-" <> to_string(UUID.uuid1())

  defp _write_events(
         stream \\ _random_stream_name(),
         events \\ [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]
       ) do
    proto_events =
      Enum.map(events, fn event ->
        ExMsg.NewEvent.new(
          event_id: Extreme.Tools.generate_uuid(),
          event_type: to_string(event.__struct__),
          data_content_type: 0,
          metadata_content_type: 0,
          data: :erlang.term_to_binary(event),
          metadata: ""
        )
      end)

    ExMsg.WriteEvents.new(
      event_stream_id: stream,
      expected_version: -2,
      events: proto_events,
      require_master: false
    )
  end

  defp _delete_stream(stream, hard_delete) do
    ExMsg.DeleteStream.new(
      event_stream_id: stream,
      expected_version: -2,
      require_master: false,
      hard_delete: hard_delete
    )
  end

  defp _read_events(stream, start \\ 0, count \\ 1) do
    ExMsg.ReadStreamEvents.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: count,
      resolve_link_tos: true,
      require_master: false
    )
  end

  defp _read_events_backward(stream, start, count) do
    ExMsg.ReadStreamEventsBackward.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: count,
      resolve_link_tos: true,
      require_master: false
    )
  end
end

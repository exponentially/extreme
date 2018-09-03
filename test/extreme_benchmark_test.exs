defmodule ExtremeBenchmarkTest do
  use ExUnit.Case, async: false
  alias Extreme.Messages, as: ExMsg
  require Logger

  defmodule(PersonCreated, do: defstruct([:name]))
  defmodule(PersonChangedName, do: defstruct([:name]))

  @base_name ExtremeBenchmarkTest

  setup_all do
    {:ok, _} = Extreme.start_link(@base_name, _test_configuration())
    :ok
  end

  describe "Benchmark" do
    @tag :benchmark
    test "writing 2 events 500 times" do
      stream = _random_stream_name()

      fun = fn ->
        for(_ <- 0..499, do: Extreme.execute(@base_name, _write_events(stream)))
      end

      time =
        fun
        |> :timer.tc()
        |> elem(0)

      time
      |> _format()
      |> IO.inspect(label: "Writing 2 events 500 times in")

      assert time < 10_000_000
    end

    @tag :benchmark
    test "writing 1_000 events at once" do
      num_events = 1_000
      stream = _random_stream_name()

      events =
        1..num_events
        |> Enum.map(fn _ -> %PersonCreated{name: "Pera Peric"} end)

      assert Enum.count(events) == num_events

      fun = fn ->
        Extreme.execute(@base_name, _write_events(stream, events))
      end

      time =
        fun
        |> :timer.tc()
        |> elem(0)

      time
      |> _format()
      |> IO.inspect(label: "Writing #{num_events} events at once in")

      assert time < 10_000_000
    end

    @tag :benchmark
    test "reading and writing simultaneously is ok" do
      num_initial_events = 10_000
      num_additional_events = 1_000
      stream = _random_stream_name()

      initial_events =
        1..num_initial_events
        |> Enum.map(fn _ -> %PersonCreated{name: "Pera Peric"} end)

      additional_events =
        1..num_additional_events
        |> Enum.map(fn _ -> %PersonCreated{name: "Pera Peric II"} end)

      {time, _} =
        :timer.tc(fn ->
          Extreme.execute(@base_name, _write_events(stream, initial_events))
        end)

      time
      |> _format()
      |> IO.inspect(label: "Written initial #{num_initial_events |> _format("")} events in")

      spawn_link(fn ->
        IO.inspect("Start writing additional events...")

        {time, _} =
          :timer.tc(fn ->
            Extreme.execute(@base_name, _write_events(stream, additional_events))
          end)

        time
        |> _format
        |> IO.inspect(
          label: "Written additional #{num_additional_events |> _format("")} events in"
        )
      end)

      p = self()

      spawn_link(fn ->
        num_total_events = num_initial_events + num_additional_events
        IO.inspect("Start reading...")

        read_batch_size = 1000

        {time, _} =
          :timer.tc(fn ->
            read_events =
              1..((num_initial_events + num_additional_events)
                  |> Integer.floor_div(read_batch_size))
              |> Stream.flat_map(fn x ->
                {:ok, %{events: events}} =
                  Extreme.execute(
                    @base_name,
                    _read_events(stream, x * read_batch_size - read_batch_size, read_batch_size)
                  )

                events
              end)
              |> Stream.map(fn event -> event.event.data |> :erlang.binary_to_term() end)

            assert read_events |> Enum.count() == num_total_events
            assert %PersonCreated{} = read_events |> Enum.take(1) |> List.first()
          end)

        time
        |> _format()
        |> IO.inspect(
          label:
            "Read #{num_total_events |> _format("")} events (#{read_batch_size |> _format("")} per read) in"
        )

        send(p, :all_events_read)
      end)

      assert_receive(:all_events_read, 60_000)
    end
  end

  defp _test_configuration,
    do: Application.get_env(:extreme, :event_store)

  defp _random_stream_name, do: "extreme_test-" <> to_string(UUID.uuid1())

  defp _write_events(
         stream,
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

  defp _read_events(stream, start, count) do
    ExMsg.ReadStreamEvents.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: count,
      resolve_link_tos: true,
      require_master: false
    )
  end

  defp _format(number, sufix \\ " µs") do
    number
    |> Integer.digits()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(fn token -> token |> Enum.reverse() |> Enum.join() end)
    |> Enum.reverse()
    |> Enum.join(",")
    |> Kernel.<>(sufix)
  end
end

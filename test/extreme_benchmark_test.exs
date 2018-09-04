defmodule ExtremeBenchmarkTest do
  use ExUnit.Case, async: false
  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event

  describe "Benchmark" do
    @tag :benchmark
    test "writing 10 events 100 times" do
      stream = Helpers.random_stream_name()

      events =
        1..10
        |> Enum.map(fn _ -> %Event.PersonCreated{name: "Alan Ford"} end)

      fun = fn ->
        for(_ <- 1..100, do: TestConn.execute(Helpers.write_events(stream, events)))
      end

      time =
        fun
        |> :timer.tc()
        |> elem(0)

      time
      |> _format(" µs")
      |> IO.inspect(label: "Writing 10 events 100 times in")

      assert time < 10_000_000
    end

    @tag :benchmark
    test "writing 1_000 events at once" do
      num_events = 1_000
      stream = Helpers.random_stream_name()

      events =
        1..num_events
        |> Enum.map(fn _ -> %Event.PersonCreated{name: "Pera Peric"} end)

      assert Enum.count(events) == num_events

      fun = fn ->
        TestConn.execute(Helpers.write_events(stream, events))
      end

      time =
        fun
        |> :timer.tc()
        |> elem(0)

      time
      |> _format(" µs")
      |> IO.inspect(label: "Writing #{num_events} events at once in")

      assert time < 10_000_000
    end

    @tag :benchmark
    test "reading and writing simultaneously is ok" do
      num_initial_events = 10_000
      num_additional_events = 1_000
      stream = Helpers.random_stream_name()

      initial_events =
        1..num_initial_events
        |> Enum.map(fn _ -> %Event.PersonCreated{name: "Pera Peric"} end)

      additional_events =
        1..num_additional_events
        |> Enum.map(fn _ -> %Event.PersonCreated{name: "Pera Peric II"} end)

      {time, _} =
        :timer.tc(fn ->
          TestConn.execute(Helpers.write_events(stream, initial_events))
        end)

      time
      |> _format(" µs")
      |> IO.inspect(label: "Written initial #{num_initial_events |> _format()} events in")

      spawn_link(fn ->
        IO.inspect("Start writing additional events...")

        {time, _} =
          :timer.tc(fn ->
            TestConn.execute(Helpers.write_events(stream, additional_events))
          end)

        time
        |> _format(" µs")
        |> IO.inspect(label: "Written additional #{num_additional_events |> _format()} events in")
      end)

      p = self()

      spawn_link(fn ->
        IO.inspect("Start reading...")

        num_total_events = num_initial_events + num_additional_events
        read_batch_size = 1000

        {time, _} =
          :timer.tc(fn ->
            read_events =
              1..((num_initial_events + num_additional_events)
                  |> Integer.floor_div(read_batch_size))
              |> Stream.flat_map(fn x ->
                {:ok, %{events: events}} =
                  TestConn.execute(
                    Helpers.read_events(
                      stream,
                      x * read_batch_size - read_batch_size,
                      read_batch_size
                    )
                  )

                events
              end)
              |> Stream.map(fn event -> event.event.data |> :erlang.binary_to_term() end)

            assert read_events |> Enum.count() == num_total_events
            assert %Event.PersonCreated{} = read_events |> Enum.take(1) |> List.first()
          end)

        time
        |> _format(" µs")
        |> IO.inspect(
          label:
            "Read #{num_total_events |> _format()} events (#{read_batch_size |> _format()} per read) in"
        )

        send(p, :all_events_read)
      end)

      assert_receive(:all_events_read, 60_000)

      # Assert there are no leaks
      assert %{received_data: ""} = TestConn.Connection |> :sys.get_state()
      %{requests: requests} = TestConn.RequestManager |> :sys.get_state()
      assert Enum.empty?(requests)

      assert 0 ==
               Extreme.RequestManager._process_supervisor_name(TestConn)
               |> Supervisor.which_children()
               |> Enum.count()
    end
  end

  defp _format(number, sufix \\ "") do
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

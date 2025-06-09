defmodule Extreme.ReadingTest do
  use ExUnit.Case, async: true

  alias ExtremeTest.Helpers
  alias ExtremeTest.Events, as: Event
  alias Extreme.Messages, as: ExMsg

  describe "reading forwards" do
    test "returns error if stream doesn't exist" do
      assert {:error, :no_stream} =
               TestConn.read_events("non_existing", fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      refute_receive {:event_processed, _}
    end

    test "all events from start in a single batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 100]

      assert :finished =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "all events from start in multiple batches" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 3]

      assert :finished =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from non-zero starting point" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 3, from_event_number: 10]

      assert :finished =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 10..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from start until specified event number (exclusive) with full last batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 3, read_until: 6]

      assert :finished =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 0..5 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from start until specified event number (exclusive) with partial last batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 3, read_until: 4]

      assert :finished =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 0..3 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "can be stopped" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 7]

      assert {:stopped, %ExMsg.ResolvedIndexedEvent{event: %{event_number: 12}}} =
               TestConn.read_events(stream, opts, fn %{event: event} = msg ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 12"} ->
                     {:stop, msg}

                   other ->
                     send(self(), {:event_processed, other})
                     :ok
                 end
               end)

      for i <- 0..11 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "stops with error on unexpected processing response" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 8]

      assert {:error, :unexpected_processing_response, :invalid_response} =
               TestConn.read_events(stream, opts, fn %{event: event} ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 13"} ->
                     :invalid_response

                   other ->
                     send(self(), {:event_processed, other})
                     :ok
                 end
               end)

      for i <- 0..12 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end
  end

  describe "reading backwards" do
    test "returns error if stream doesn't exist" do
      assert {:error, :no_stream} =
               TestConn.read_events_backwards("non_existing", fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      refute_receive {:event_processed, _}
    end

    test "all events in a single batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 100]

      assert :finished =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- (count - 1)..0//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "all events in multiple batches" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 3]

      assert :finished =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- (count - 1)..0//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from non-minus-one starting point" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 2, from_event_number: 10]

      assert :finished =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 10..0//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from minus-one until specified event number (exclusive) in a single batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 50, read_until: 6]

      assert :finished =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 19..7//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "events from non-minus-one until specified event number (exclusive)" do
      count = 20
      {stream, _events} = _write_events(count)

      # kada je ceo batch onda radi ... nesto zeza sa racunanjem kada da pre stane da cita
      # proveri isto read_until kada krece od -1
      opts = [per_page: 3, from_event_number: 10, read_until: 6]

      assert :finished =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 send(self(), {:event_processed, :erlang.binary_to_term(event.data)})
                 :ok
               end)

      for i <- 10..7//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "can be stopped" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 2]

      assert {:stopped, nil} =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 13"} ->
                     :stop

                   other ->
                     send(self(), {:event_processed, other})
                     :ok
                 end
               end)

      for i <- (count - 1)..14//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end

    test "stops with error on unexpected processing response" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 2]

      assert {:error, :unexpected_processing_response, :invalid_response} =
               TestConn.read_events_backwards(stream, opts, fn %{event: event} ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 13"} ->
                     :invalid_response

                   other ->
                     send(self(), {:event_processed, other})
                     :ok
                 end
               end)

      for i <- (count - 1)..14//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end
  end

  describe "reduce forwards" do
    test "returns error if stream doesn't exist" do
      assert {:error, :no_stream} =
               :whatever
               |> TestConn.reduce_events("non_existing", fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc})
                   {:ok, acc}
               end)

      refute_receive {:event_processed, _}
    end

    test "all events from start in a single batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 100]

      assert {:finished, 20} =
               TestConn.reduce_events(0, stream, opts, fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc})
                   {:ok, acc + 1}
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}, ^i}
      end

      refute_receive {:event_processed, _, _}
    end

    test "all events from start in a multiple batches" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 6]

      assert {:finished, 20} =
               TestConn.reduce_events(0, stream, opts, fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc})
                   {:ok, acc + 1}
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}, ^i}
      end

      refute_receive {:event_processed, _, _}
    end

    test "can be stopped" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 7]

      assert {:stopped,
              %{
                stopped_on: %ExMsg.ResolvedIndexedEvent{event: %{event_number: 12}},
                last_processed: 11
              }} =
               %{stopped_on: nil, last_processed: nil}
               |> TestConn.reduce_events(stream, opts, fn %{event: event} = msg, acc ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 12"} ->
                     {:stop, %{acc | stopped_on: msg}}

                   other ->
                     send(self(), {:event_processed, other})
                     {:ok, %{acc | last_processed: event.event_number}}
                 end
               end)

      for i <- 0..11 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end
  end

  describe "reduce backwards" do
    test "returns error if stream doesn't exist" do
      assert {:error, :no_stream} =
               :whatever
               |> TestConn.reduce_events_backwards("non_existing", fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc})
                   {:ok, acc}
               end)

      refute_receive {:event_processed, _}
    end

    test "all events from start in a single batch" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 100]

      assert {:finished, 0} =
               TestConn.reduce_events_backwards(20, stream, opts, fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc - 1})
                   {:ok, acc - 1}
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}, ^i}
      end

      refute_receive {:event_processed, _, _}
    end

    test "all events from start in a multiple batches" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 6]

      assert {:finished, 0} =
               TestConn.reduce_events_backwards(20, stream, opts, fn
                 %{event: event}, acc ->
                   send(self(), {:event_processed, :erlang.binary_to_term(event.data), acc - 1})
                   {:ok, acc - 1}
               end)

      for i <- 0..(count - 1) do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}, ^i}
      end

      refute_receive {:event_processed, _, _}
    end

    test "can be stopped" do
      count = 20
      {stream, _events} = _write_events(count)

      opts = [per_page: 6]

      assert {:stopped,
              %{
                stopped_on: %ExMsg.ResolvedIndexedEvent{event: %{event_number: 12}},
                last_processed: 13
              }} =
               %{stopped_on: nil, last_processed: nil}
               |> TestConn.reduce_events_backwards(stream, opts, fn %{event: event} = msg, acc ->
                 event.data
                 |> :erlang.binary_to_term()
                 |> case do
                   %Event.PersonCreated{name: "Reading 12"} ->
                     {:stop, %{acc | stopped_on: msg}}

                   other ->
                     send(self(), {:event_processed, other})
                     {:ok, %{acc | last_processed: event.event_number}}
                 end
               end)

      for i <- (count - 1)..13//-1 do
        expected_name = "Reading #{i}"
        assert_received {:event_processed, %Event.PersonCreated{name: ^expected_name}}
      end

      refute_receive {:event_processed, _}
    end
  end

  defp _gen_events(count) do
    0..(count - 1)
    |> Enum.map(fn i ->
      %Event.PersonCreated{name: "Reading #{i}"}
    end)
  end

  defp _write_events(count) do
    stream = Helpers.random_stream_name()

    events = _gen_events(count)

    {:ok, %ExMsg.WriteEventsCompleted{}} =
      TestConn.execute(Helpers.write_events(stream, events))

    {stream, events}
  end
end

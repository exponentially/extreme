defmodule Extreme.Benchmark.Writer do
  use GenServer
  alias Extreme.Benchmark.StatsServer

  defmodule SomeEvent do
    defstruct name: ""
  end

  def start_link({event_count, es_name}, opts \\ []) do
    stream = "bech-" <> UUID.uuid4()
    GenServer.start_link(__MODULE__, {stream, event_count, es_name}, opts)
  end

  # SERVER

  def init({stream, event_count, es_name}) do
    GenServer.cast(self(), :send)

    {:ok,
     %{
       stream: stream,
       event_count: event_count,
       es_name: es_name
     }}
  end

  def handle_cast(:send, s) do
    fun = fn -> stream_events(s.stream, s.event_count, s.es_name) end

    time =
      fun
      |> :timer.tc()
      |> elem(0)

    StatsServer.report({s.event_count, time})
    GenServer.cast(self(), :send)
    {:noreply, s}
  end

  def handle_cast({:inc, event_count}, s) do
    {:noreply, %{s | event_count: event_count}}
  end

  defp stream_events(stream_name, event_count, es_name) do
    # todo: report failures to calculate SLA
    write = write_events(event_count, stream_name)
    {:ok, _} = Extreme.execute(es_name, write)
  end

  defp write_events(event_count, stream) do
    events = Enum.map(1..event_count, &struct(SomeEvent, name: "Pera Peric #{&1}"))

    proto_events =
      Enum.map(events, fn event ->
        Extreme.Msg.NewEvent.new(
          event_id: Extreme.Tools.gen_uuid(),
          event_type: to_string(event.__struct__),
          data_content_type: 1,
          metadata_content_type: 1,
          data: Poison.encode!(event),
          metadata: ""
        )
      end)

    Extreme.Msg.WriteEvents.new(
      event_stream_id: stream,
      expected_version: -2,
      events: proto_events,
      require_master: false
    )
  end
end

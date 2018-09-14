defmodule Extreme.Benchmark.StatsServer do
  use GenServer
  require Logger

  @workers 10
  @conns 1
  @dump_timeout 20_000
  @increment 50

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def add_workers(num, es_name) do
    GenServer.cast(:stats, {:add_workers, num, es_name})
  end

  def inc() do
    GenServer.cast(:stats, :inc)
  end

  def report(report) do
    GenServer.cast(:stats, {:report, report})
  end

  def range() do
    1..@conns
  end

  # SERVER

  def init(_) do
    for i <- range() do
      add_workers(@workers, :"extreme_#{i}")
    end

    Process.send_after(self(), :dump, @dump_timeout)

    {:ok,
     %{
       workers: [],
       event_count: 1,
       events: 0,
       ips: 0,
       total_time: 0
     }}
  end

  def handle_cast({:add_workers, num, es_name}, s) do
    pids =
      Enum.map(1..num, fn _ ->
        {:ok, pid} =
          DynamicSupervisor.start_child(:wroker_sup, %{
            id: Extreme.Benchmark.Writer,
            start: {Extreme.Benchmark.Writer, :start_link, [{s.event_count, es_name}, []]}
          })

        pid
      end)

    {:noreply, %{s | workers: s.workers ++ pids}}
  end

  def handle_cast({:report, {count, time}}, %{ips: ips, total_time: total_time, events: events}=s) do
    events = count + events
    ips = ips + 1
    total_time = time + total_time

    {:noreply, %{s | ips: ips, events: events, total_time: total_time}}
  end

  def handle_cast(:inc, s) do
    event_count = if s.event_count == 1, do: @increment, else: s.event_count + @increment
    s = %{s | event_count: event_count}

    for pid <- s.workers do
      GenServer.cast(pid, {:inc, s.event_count})
    end

    {:noreply, s}
  end

  def handle_info(:dump, s) do
    print_report(s)
    inc()
    Process.send_after(self(), :dump, @dump_timeout)
    {:noreply, %{s | ips: 0, events: 0, total_time: 0}}
  end

  def handle_info(_, s) do
    {:noreply, s}
  end

  defp print_report(%{event_count: event_count, ips: ips, events: events, total_time: total_time}) do
    if ips > 0 do

      avg = total_time / ips
      ips = ips * 1_000 / @dump_timeout

      Logger.info(
        "#{event_count} events, IPS: #{Float.round(ips, 2)} AVG: #{format_msc(avg)}, TOTAL EVENTS/sec: #{events * 1_000/@dump_timeout}"
      )
    else
      Logger.info("NO STATS YET")
    end
  end

  defp format_msc(mcs) do
    cond do
      mcs >= 1_000_000 ->
        to_string(:io_lib.format("~p s", [Float.round(mcs / 1_000_000, 2)]))

      mcs >= 1_000 ->
        to_string(:io_lib.format("~p ms", [Float.round(mcs / 1_000, 2)]))

      true ->
        to_string(:io_lib.format("~p µs", [Float.round(mcs, 2)]))
    end
  end
end

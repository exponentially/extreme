defmodule FakeRequestManager do
  @moduledoc "Stands in for `Extreme.RequestManager`, replying to reads from a script, then `no_stream`."
  use GenServer
  alias Extreme.Messages, as: ExMsg

  def start_link(base_name, read_replies) do
    __MODULE__
    |> GenServer.start_link(read_replies, name: Extreme.RequestManager._name(base_name))
  end

  def reads(base_name) do
    base_name
    |> Extreme.RequestManager._name()
    |> GenServer.call(:reads)
  end

  @impl true
  def init(read_replies), do: {:ok, %{read_replies: read_replies, reads: 0}}

  @impl true
  def handle_call(
        {:execute, _correlation_id, %ExMsg.SubscribeToStream{}, _timeout},
        _from,
        state
      ),
      do: {:reply, {:ok, %ExMsg.SubscriptionConfirmation{last_event_number: 2}}, state}

  def handle_call({:execute, _correlation_id, %ExMsg.ReadStreamEvents{}, _timeout}, _from, state) do
    {reply, read_replies} = _next_reply(state.read_replies)
    {:reply, reply, %{state | read_replies: read_replies, reads: state.reads + 1}}
  end

  def handle_call(:reads, _from, state), do: {:reply, state.reads, state}

  @impl true
  def handle_cast({:unregister_subscription, _correlation_id}, state), do: {:noreply, state}

  defp _next_reply([{:events, numbers} | rest]) do
    events =
      for number <- numbers,
          do: %ExMsg.ResolvedIndexedEvent{event: %ExMsg.EventRecord{event_number: number}}

    next_event_number = List.last(numbers) + 1

    {{:ok,
      %ExMsg.ReadStreamEventsCompleted{events: events, next_event_number: next_event_number}},
     rest}
  end

  defp _next_reply([:no_stream | rest]), do: {_no_stream(), rest}
  defp _next_reply([]), do: {_no_stream(), []}

  defp _no_stream,
    do: {:error, :no_stream, %ExMsg.ReadStreamEventsCompleted{result: :no_stream}}
end

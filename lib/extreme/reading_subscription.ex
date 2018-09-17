defmodule Extreme.ReadingSubscription do
  use GenServer
  require Logger
  alias Extreme.RequestManager
  alias Extreme.Messages, as: Msg
  alias Extreme.SharedSubscription, as: Shared

  defmodule State do
    defstruct ~w(base_name correlation_id subscriber read_params buffered_messages read_until status)a
  end

  @doc """
  Spawns Subscription for read_and_stay_subscribed
  """
  def start_link(base_name, correlation_id, subscriber, read_params) do
    GenServer.start_link(
      __MODULE__,
      {base_name, correlation_id, subscriber, read_params}
    )
  end

  @impl true
  def init(
        {base_name, correlation_id, subscriber,
         {stream, from_event_number, per_page, resolve_link_tos, require_master}}
      ) do
    read_params = %{
      stream: stream,
      from_event_number: from_event_number,
      per_page: per_page,
      resolve_link_tos: resolve_link_tos,
      require_master: require_master
    }

    state = %State{
      base_name: base_name,
      correlation_id: correlation_id,
      subscriber: subscriber,
      read_params: read_params,
      status: :reading_events,
      buffered_messages: [],
      read_until: -1
    }

    {:ok, subscription_confirmation} = Shared.subscribe(state)
    read_until = subscription_confirmation.last_event_number + 1
    GenServer.cast(self(), :read_events)

    {:ok, %State{state | read_until: read_until}}
  end

  @impl true
  def handle_call(:unsubscribe, from, state) do
    :ok = Shared.unsubscribe(from, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:process_push, fun}, %{status: :subscribed} = state),
    do: Shared.process_push(fun, state)

  def handle_cast({:process_push, fun}, %{buffered_messages: buffered_messages} = state) do
    case fun.() do
      {_auth, _correlation_id, %Msg.StreamEventAppeared{} = e} ->
        {:noreply, %{state | buffered_messages: [e.event | buffered_messages]}}
    end
  end

  # We have read all planned events. Now lets push buffered messages.
  def handle_cast(
        :read_events,
        %{read_params: %{from_event_number: from}, read_until: from} = state
      ) do
    GenServer.cast(self(), :push_buffered_messages)
    {:noreply, %{state | status: :pushing_buffered}}
  end

  def handle_cast(:read_events, state) do
    {read_events_message, keep_reading} =
      state.read_params
      |> _read_events_message(state.read_until)

    state =
      if keep_reading,
        do: state,
        else: %{state | status: :pushing_buffered}

    state =
      state.base_name
      |> RequestManager.execute(read_events_message, state.correlation_id)
      |> _process_read_response(state)

    {:noreply, state}
  end

  def handle_cast(:push_buffered_messages, state) do
    state.buffered_messages
    |> Enum.reverse()
    |> Enum.each(fn e -> send(state.subscriber, {:on_event, e}) end)

    send(state.subscriber, :caught_up)
    {:noreply, %{state | status: :subscribed, buffered_messages: []}}
  end

  defp _process_read_response({:error, :stream_hard_deleted}, state) do
    Logger.error(fn -> "Stream is hard deleted" end)

    send(state.subscriber, {:extreme, :stream_hard_deleted})
    RequestManager._unregister_subscription(state.base_name, state.correlation_id)
    {:stop, {:shutdown, :stream_hard_deleted}, state}
  end

  defp _process_read_response({:warn, :stream_soft_deleted, _}, state) do
    Logger.warn(fn -> "Stream doesn't exist yet" end)

    {:extreme, :warn, :stream_soft_deleted, state.read_params.stream}
    |> _caught_up(state)
  end

  defp _process_read_response({:warn, :non_existing_stream}, state) do
    Logger.warn(fn -> "Stream doesn't exist yet" end)

    {:extreme, :warn, :non_existing_stream, state.read_params.stream}
    |> _caught_up(state)
  end

  defp _process_read_response({:ok, %Msg.ReadStreamEventsCompleted{} = response}, state) do
    Logger.debug(fn -> "Last read event: #{inspect(response.next_event_number - 1)}" end)
    response.events |> Enum.each(fn e -> send(state.subscriber, {:on_event, e}) end)

    response.next_event_number
    |> _send_next_request(state)

    {:noreply, state}
  end

  defp _caught_up(message, state) do
    send(state.subscriber, message)
    send(state.subscriber, :caught_up)
    GenServer.cast(self(), :push_buffered_messages)
    {:noreply, state}
  end

  defp _send_next_request(_, %{status: :pushing_buffered} = state) do
    GenServer.cast(self(), :push_buffered_messages)
    state
  end

  defp _send_next_request(next_event_number, state) do
    GenServer.cast(self(), :read_events)
    %{state | read_params: %{state.read_params | from_event_number: next_event_number}}
  end

  defp _read_events_message(%{from_event_number: from, per_page: per_page} = params, read_until)
       when from + per_page < read_until do
    result =
      Msg.ReadStreamEvents.new(
        event_stream_id: params.stream,
        from_event_number: from,
        max_count: per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {result, true}
  end

  defp _read_events_message(params, read_until) do
    result =
      Msg.ReadStreamEvents.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: read_until - params.from_event_number,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {result, false}
  end
end

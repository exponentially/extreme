defmodule Extreme.ReadingSubscription do
  use GenServer
  require Logger
  alias Extreme.RequestManager
  alias Extreme.Messages, as: Msg
  alias Extreme.SharedSubscription, as: Shared

  defmodule State do
    defstruct ~w(base_name correlation_id subscriber read_params buffered_messages read_until status no_stream_retries)a
  end

  @max_no_stream_retries 50
  @no_stream_retry_delay 20

  @doc """
  Spawns Subscription for read_and_stay_subscribed
  """
  def start_link(base_name, correlation_id, subscriber, read_params) do
    GenServer.start_link(
      __MODULE__,
      {base_name, correlation_id, subscriber, read_params}
    )
  end

  @impl GenServer
  def init(
        {base_name, correlation_id, subscriber,
         {stream, from_event_number, per_page, resolve_link_tos, require_master, ack_timeout}}
      ) do
    read_params = %{
      stream: stream,
      from_event_number: from_event_number,
      per_page: per_page,
      resolve_link_tos: resolve_link_tos,
      require_master: require_master,
      ack_timeout: ack_timeout
    }

    state = %State{
      base_name: base_name,
      correlation_id: correlation_id,
      subscriber: subscriber,
      read_params: read_params,
      status: :reading_events,
      buffered_messages: [],
      read_until: -1,
      no_stream_retries: 0
    }

    {:ok, subscription_confirmation} = Shared.subscribe(state)
    read_until = subscription_confirmation.last_event_number + 1
    GenServer.cast(self(), :read_events)

    {:ok, %State{state | read_until: read_until}}
  end

  @impl GenServer
  def handle_cast(:unsubscribe, state) do
    :ok = Shared.unsubscribe(state)
    {:noreply, state}
  end

  def handle_cast({:process_push, fun}, %{status: :subscribed} = state) do
    push = fun.()

    push
    |> _before_start?(state.read_params.from_event_number)
    |> if(do: {:noreply, state}, else: Shared.process_push(fn -> push end, state))
  end

  def handle_cast({:process_push, fun}, state) do
    fun.()
    |> _buffer_push(state)
  end

  # We have read all planned events. Now lets push buffered messages.
  def handle_cast(
        :read_events,
        %{read_params: %{from_event_number: from}, read_until: read_until} = state
      )
      when from >= read_until do
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

    state.base_name
    |> RequestManager.execute(read_events_message, Extreme.Tools.generate_uuid())
    |> _process_read_response(state)
  end

  def handle_cast(:push_buffered_messages, state) do
    state.buffered_messages
    |> Enum.reverse()
    |> Enum.reject(&(_event_number(&1) < state.read_params.from_event_number))
    |> Enum.any?(fn msg ->
      state.subscriber
      |> Shared.on_event(msg, state.read_params.ack_timeout)
      |> case do
        :ok ->
          false

        :stop ->
          Logger.info("Processing of buffered message is stopped")
          true

        error ->
          Logger.warning(
            "Processing of buffered message didn't succeed: #{inspect([msg, error])}"
          )

          true
      end
    end)
    # One msg processing didn't succeed (maybe we got `:stop`)
    |> if do
      RequestManager.unregister_subscription(state.base_name, state.correlation_id)
      {:stop, {:shutdown, :processing_of_buffered_message_failed}, state}
    else
      send(state.subscriber, :caught_up)
      {:noreply, %{state | status: :subscribed, buffered_messages: []}}
    end
  end

  @impl GenServer
  def handle_info(:read_events, state), do: handle_cast(:read_events, state)

  defp _process_read_response({:error, :stream_deleted, _}, state) do
    Logger.error(fn -> "Stream is hard deleted" end)

    send(state.subscriber, {:extreme, :error, :stream_deleted, state.read_params.stream})
    RequestManager.unregister_subscription(state.base_name, state.correlation_id)
    {:stop, {:shutdown, :stream_deleted}, state}
  end

  # ESDB acks a write to a soft-deleted stream before the metadata that undeletes it is readable.
  defp _process_read_response({:error, :no_stream, _}, %{no_stream_retries: retries} = state)
       when retries < @max_no_stream_retries do
    Process.send_after(self(), :read_events, @no_stream_retry_delay)
    {:noreply, %{state | status: :reading_events, no_stream_retries: retries + 1}}
  end

  defp _process_read_response({:error, :no_stream, _}, state) do
    Logger.warning(fn -> "Stream doesn't exist yet" end)

    {:extreme, :warn, :stream_soft_deleted, state.read_params.stream}
    |> _caught_up(state)
  end

  defp _process_read_response(
         {:error, reason, %Msg.ReadStreamEventsCompleted{} = response},
         state
       ) do
    Logger.error(fn -> "Reading events failed: #{inspect([reason, response.error])}" end)

    send(state.subscriber, {:extreme, :error, reason, state.read_params.stream})
    RequestManager.unregister_subscription(state.base_name, state.correlation_id)
    {:stop, {:shutdown, reason}, state}
  end

  defp _process_read_response({:ok, %Msg.ReadStreamEventsCompleted{} = response}, state) do
    Logger.debug(fn -> "Last read event: #{inspect(response.next_event_number - 1)}" end)

    response.events
    |> Enum.reduce_while(false, fn msg, _ ->
      state.subscriber
      |> Shared.on_event(msg, state.read_params.ack_timeout)
      |> case do
        :ok ->
          {:cont, false}

        :stop ->
          Logger.info("Processing of read message is stopped")
          {:halt, true}

        error ->
          Logger.warning(
            "Processing of buffered message didn't succeed: #{inspect([msg, error])}"
          )

          {:halt, true}
      end
    end)
    # One event processing didn't succeed (maybe we got `:stop`)
    |> if do
      RequestManager.unregister_subscription(state.base_name, state.correlation_id)
      {:stop, {:shutdown, :processing_of_read_events_failed}, state}
    else
      state =
        response.next_event_number
        |> _send_next_request(%{state | no_stream_retries: 0})

      {:noreply, state}
    end
  end

  defp _buffer_push({_auth, _correlation_id, %Msg.StreamEventAppeared{} = e}, state),
    do: {:noreply, %{state | buffered_messages: [e.event | state.buffered_messages]}}

  defp _buffer_push(push, state), do: Shared.process_push(fn -> push end, state)

  defp _before_start?({_auth, _correlation_id, %Msg.StreamEventAppeared{} = e}, from),
    do: _event_number(e.event) < from

  defp _before_start?(_push, _from), do: false

  # A resolved link's position in the subscribed stream is the link's own number.
  defp _event_number(%Msg.ResolvedEvent{link: %Msg.EventRecord{event_number: number}}),
    do: number

  defp _event_number(%Msg.ResolvedEvent{event: %Msg.EventRecord{event_number: number}}),
    do: number

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
    state = %{state | read_params: %{state.read_params | from_event_number: next_event_number}}
    Logger.debug(fn -> "Reading new batch of events #{inspect(state.read_params)}" end)
    GenServer.cast(self(), :read_events)
    state
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

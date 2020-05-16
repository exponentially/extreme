defmodule Extreme.PersistentSubscription do
  @moduledoc "A persistent subscription process"

  use GenServer
  require Logger
  alias Extreme.SharedSubscription, as: Shared
  alias Extreme.RequestManager
  alias Extreme.Messages, as: Msg

  defmodule State do
    defstruct ~w(base_name correlation_id stream group subscriber allowed_in_flight_messages status subscription_id)a
  end

  def start_link(
        base_name,
        correlation_id,
        stream,
        group,
        subscriber,
        allowed_in_flight_messages
      ) do
    GenServer.start_link(
      __MODULE__,
      {base_name, correlation_id, stream, group, subscriber, allowed_in_flight_messages}
    )
  end

  @doc """
  Calls `server` with :unsubscribe message. `server` can be either `Subscription` or `ReadingSubscription`.
  """
  def unsubscribe(server),
    do: GenServer.call(server, :unsubscribe)

  @impl true
  def init({base_name, correlation_id, stream, group, subscriber, allowed_in_flight_messages}) do
    state = %State{
      base_name: base_name,
      correlation_id: correlation_id,
      stream: stream,
      group: group,
      subscriber: subscriber,
      allowed_in_flight_messages: allowed_in_flight_messages,
      status: :initialized
    }

    send(self(), :subscribe)

    {:ok, state}
  end

  @impl true
  def handle_call(:unsubscribe, from, state) do
    :ok = Shared.unsubscribe(from, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:process_push, fun}, state) do
    process_push(fun, state)
  end

  @impl true
  def handle_info({:ack, successful, failed}, state) do
    build_and_send_responses(successful, failed, state)

    {:noreply, state}
  end

  def handle_info(:subscribe, state) do
    message =
      Extreme.Messages.ConnectToPersistentSubscription.new(
        subscription_id: state.group,
        event_stream_id: state.stream,
        allowed_in_flight_messages: state.allowed_in_flight_messages
      )

    :ok =
      state.base_name
      |> RequestManager._name()
      |> GenServer.cast({:execute, state.correlation_id, message})

    {:noreply, state}
  end

  def process_push(fun, state), do: fun.() |> _process_push(state)

  defp _process_push(
         {_auth, _correlation_id, %Msg.PersistentSubscriptionConfirmation{subscription_id: subscription_id} = confirmation},
         state
       ) do
    Logger.debug(fn -> "Successfully subscribed #{inspect(confirmation)}" end)

    {:noreply, %State{state | status: :subscribed, subscription_id: subscription_id}}
  end

  defp _process_push(
         {_auth, _correlation_id, %Msg.SubscriptionDropped{reason: reason}},
         state
       ) do
    Logger.debug(fn ->
      "Unsubscribed from persistent subscription by server because #{inspect(reason)}"
    end)

    {:stop, :normal, state}
  end

  defp _process_push(
         {_auth, correlation_id, %Msg.PersistentSubscriptionStreamEventAppeared{} = e},
         state
       ) do
    on_event(state.subscriber, e, correlation_id)

    {:noreply, state}
  end

  def on_event(subscriber, event, correlation_id),
    do: send(subscriber, {:on_event, event, correlation_id})

  defp build_and_send_responses(successful, failed, state) do
    successful
    |> Enum.reduce(%{}, fn %{event_id: event_id, correlation_id: correlation_id}, acc ->
      Map.update(acc, correlation_id, [event_id], &[event_id | &1])
    end)
    |> Enum.map(fn {correlation_id, event_ids} ->
      maybe_respond(event_ids, :ack, state, correlation_id)
    end)

    failed
    |> Enum.reduce(%{}, fn %{event_id: event_id, correlation_id: correlation_id}, acc ->
      Map.update(acc, correlation_id, [event_id], &[event_id | &1])
    end)
    |> Enum.map(fn {correlation_id, event_ids} ->
      maybe_respond(event_ids, :nack, state, correlation_id)
    end)
  end

  def maybe_respond([] = _event_ids, _ack_or_nack, _state, _correlation_id), do: :ok

  def maybe_respond(event_ids, :ack, state, correlation_id) do
    Msg.PersistentSubscriptionAckEvents.new(
      subscription_id: state.subscription_id,
      processed_event_ids: event_ids
    )
    |> cast_req_manager(state, correlation_id)
  end

  def maybe_respond(event_ids, :nack, state, correlation_id) do
    Msg.PersistentSubscriptionNakEvents.new(
      subscription_id: state.subscription_id,
      processed_event_ids: event_ids,
      message: "3rt$",
      action: :retry
    )
    |> cast_req_manager(state, correlation_id)
  end

  def cast_req_manager(message, state, correlation_id) do
    :ok =
      state.base_name
      |> RequestManager._name()
      |> GenServer.cast({:execute, correlation_id, message})
  end
end

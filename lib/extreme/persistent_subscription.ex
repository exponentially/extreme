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

  def ack(subscription, event, correlation_id) when is_map(event) or is_binary(event) do
    ack(subscription, [event], correlation_id)
  end

  def ack(subscription, events, correlation_id) when is_list(events) do
    GenServer.cast(subscription, {:ack, events, correlation_id})
  end

  def nack(subscription, event, correlation_id, action, message \\ "")

  def nack(subscription, event, correlation_id, action, message) when is_map(event) or is_binary(event) do
    nack(subscription, [event], correlation_id, action, message)
  end

  def nack(subscription, events, correlation_id, action, message) when is_list(events) do
    GenServer.cast(subscription, {:nack, events, correlation_id, action, message})
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

  def handle_cast({:ack, events, correlation_id}, state) do
    Msg.PersistentSubscriptionAckEvents.new(
      subscription_id: state.subscription_id,
      processed_event_ids: event_ids(events)
    )
    |> cast_request_manager(state.base_name, correlation_id)

    {:noreply, state}
  end

  def handle_cast({:nack, events, correlation_id, action, message}, state) do
    Msg.PersistentSubscriptionNakEvents.new(
      subscription_id: state.subscription_id,
      processed_event_ids: event_ids(events),
      action: action,
      message: message
    )
    |> cast_request_manager(state.base_name, correlation_id)

    {:noreply, state}
  end

  @impl true
  def handle_info(:subscribe, state) do
    Msg.ConnectToPersistentSubscription.new(
      subscription_id: state.group,
      event_stream_id: state.stream,
      allowed_in_flight_messages: state.allowed_in_flight_messages
    )
    |> cast_request_manager(state.base_name, state.correlation_id)

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

  defp cast_request_manager(message, base_name, correlation_id) do
    base_name
    |> RequestManager._name()
    |> GenServer.cast({:execute, correlation_id, message})
  end

  defp event_ids(events) when is_list(events) do
    Enum.map(events, &event_id/1)
  end

  defp event_id(event_id) when is_binary(event_id), do: event_id
  defp event_id(%Msg.ResolvedIndexedEvent{link: %Msg.EventRecord{event_id: event_id}}), do: event_id
  defp event_id(%Msg.ResolvedIndexedEvent{event: %Msg.EventRecord{event_id: event_id}}), do: event_id
end

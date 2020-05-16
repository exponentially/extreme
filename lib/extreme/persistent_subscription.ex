defmodule Extreme.PersistentSubscription do
  @moduledoc "A persistent subscription process"

  use GenServer
  require Logger
  alias Extreme.SharedSubscription, as: Shared
  alias Extreme.RequestManager
  alias Extreme.Messages, as: Msg

  defmodule State do
    defstruct ~w(
      base_name
      correlation_id
      subscriber
      stream
      group
      allowed_in_flight_messages
      status
      subscription_id
    )a
  end

  def start_link(
        base_name,
        correlation_id,
        subscriber,
        stream,
        group,
        allowed_in_flight_messages
      ) do
    GenServer.start_link(
      __MODULE__,
      {base_name, correlation_id, subscriber, stream, group, allowed_in_flight_messages}
    )
  end

  @doc """
  TODO
  """
  def ack(subscription, event, correlation_id) when is_map(event) or is_binary(event) do
    ack(subscription, [event], correlation_id)
  end

  def ack(subscription, events, correlation_id) when is_list(events) do
    GenServer.cast(subscription, {:ack, events, correlation_id})
  end

  @doc """
  TODO
  """
  def nack(subscription, event, correlation_id, action, message \\ "")

  def nack(subscription, event, correlation_id, action, message)
      when is_map(event) or is_binary(event) do
    nack(subscription, [event], correlation_id, action, message)
  end

  def nack(subscription, events, correlation_id, action, message) when is_list(events) do
    GenServer.cast(subscription, {:nack, events, correlation_id, action, message})
  end

  @impl true
  def init({base_name, correlation_id, subscriber, stream, group, allowed_in_flight_messages}) do
    state = %State{
      base_name: base_name,
      correlation_id: correlation_id,
      subscriber: subscriber,
      stream: stream,
      group: group,
      allowed_in_flight_messages: allowed_in_flight_messages,
      status: :initialized
    }

    GenServer.cast(self(), :subscribe)

    {:ok, state}
  end

  @impl true
  def handle_cast(:subscribe, state) do
    Msg.ConnectToPersistentSubscription.new(
      subscription_id: state.group,
      event_stream_id: state.stream,
      allowed_in_flight_messages: state.allowed_in_flight_messages
    )
    |> cast_request_manager(state.base_name, state.correlation_id)

    {:noreply, state}
  end

  def handle_cast({:process_push, fun}, state) do
    Shared.process_push(fun, state)
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

  defp cast_request_manager(message, base_name, correlation_id) do
    base_name
    |> RequestManager._name()
    |> GenServer.cast({:execute, correlation_id, message})
  end

  defp event_ids(events) when is_list(events) do
    Enum.map(events, &event_id/1)
  end

  defp event_id(event_id) when is_binary(event_id), do: event_id

  defp event_id(%Msg.ResolvedIndexedEvent{link: %Msg.EventRecord{event_id: event_id}}),
    do: event_id

  defp event_id(%Msg.ResolvedIndexedEvent{event: %Msg.EventRecord{event_id: event_id}}),
    do: event_id
end

defmodule Extreme.PersistentSubscription do
  use GenServer
  require Logger
  alias Extreme.Msg, as: ExMsg

  def start_link(connection, subscriber, params) do
    GenServer.start_link(__MODULE__, {connection, subscriber, params})
  end

  def init({connection, subscriber, {subscription, stream, buffer_size}}) do
    state = %{
      subscriber: subscriber,
      subscription_id: nil,
      connection: connection,
      params: %{subscription: subscription, stream: stream, buffer_size: buffer_size},
      status: :initialized,
    }
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  def handle_cast(:connect, %{connection: connection, params: params} = state) do
    {:ok, %Extreme.Msg.PersistentSubscriptionConfirmation{subscription_id: subscription_id}} = GenServer.call(connection, {:subscribe, self(), connect(params)})
    Logger.debug(fn -> "Successfully connected to persistent subscription id: #{inspect subscription_id}" end)
    {:noreply, %{state | subscription_id: subscription_id, status: :subscribed}}
  end

  def handle_cast({:ok, %ExMsg.PersistentSubscriptionStreamEventAppeared{}=e, correlation_id}, %{subscriber: subscriber, subscription_id: subscription_id} = state) do
    Logger.debug(fn -> "Persistent subscription #{inspect subscription_id} event appeared: #{inspect e}" end)
    send(subscriber, {:on_event, e.event, subscription_id, correlation_id})
    {:noreply, state}
  end

  defp connect(params) do
    ExMsg.ConnectToPersistentSubscription.new(
      subscription_id: params.subscription,
      event_stream_id: params.stream,
      allowed_in_flight_messages: params.buffer_size
    )
  end
end

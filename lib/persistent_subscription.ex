defmodule Extreme.PersistentSubscription do
  use GenServer
  require Logger
  alias Extreme.Msg, as: ExMsg

  def start_link(connection_settings, subscriber, params) do
    GenServer.start_link(__MODULE__, {connection_settings, subscriber, params})
  end

  def init({connection_settings, subscriber, {subscription, stream, buffer_size}}) do
    state = %{
      connection_settings: connection_settings,
      subscriber: subscriber,
      subscription_ref: Process.monitor(subscriber),
      subscription_id: nil,
      correlation_id: nil,
      connection: nil,
      params: %{subscription: subscription, stream: stream, buffer_size: buffer_size},
      status: :initialized,
    }
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  # confirm receipt of an event
  def ack(subscription, %{link: link}) when not is_nil(link) do
    GenServer.call(subscription, {:ack, link.event_id})
  end

  def ack(subscription, %{event: event}) when not is_nil(event) do
    GenServer.call(subscription, {:ack, event.event_id})
  end

  def ack(subscription, event_id) when is_binary(event_id) do
    GenServer.call(subscription, {:ack, event_id})
  end

  def handle_cast(:connect, %{connection_settings: connection_settings, params: params} = state) do
    # create a connection to the event store for this persistent subscription
    {:ok, connection} = Extreme.start_link(connection_settings)

    {:ok, %ExMsg.PersistentSubscriptionConfirmation{subscription_id: subscription_id}} = GenServer.call(connection, {:subscribe, self(), connect(params)})

    Logger.debug(fn -> "Successfully connected to persistent subscription id: #{inspect subscription_id}" end)

    {:noreply, %{state | connection: connection, subscription_id: subscription_id, status: :subscribed}}
  end

  def handle_cast({:ok, %ExMsg.PersistentSubscriptionStreamEventAppeared{event: event} = msg, correlation_id}, %{subscription_id: subscription_id, subscriber: subscriber} = state) do
    Logger.debug(fn -> "Persistent subscription #{inspect subscription_id} event appeared: #{inspect msg}" end)
    send(subscriber, {:on_event, event})
    {:noreply, %{state | correlation_id: correlation_id}}
  end

  def handle_call({:ack, event_id}, _from, %{connection: connection, subscription_id: subscription_id, correlation_id: correlation_id} = state) do
    Logger.debug(fn -> "Persistent subscription #{inspect subscription_id} ack event id: #{inspect event_id}" end)
    :ok = GenServer.call(connection, {:ack, ack_event(subscription_id, event_id), correlation_id})
    {:reply, :ok, %{state | correlation_id: nil}}
  end

  # stop persistent subscription process when subscriber process is down
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{subscription_ref: ref, subscription_id: subscription_id} = state) do
    Logger.info(fn -> "Stopping persistent subscription #{inspect subscription_id} as subscriber is down due to: #{inspect reason}" end)
    {:stop, {:shutdown, :subscriber_down}, state}
  end

  defp connect(params) do
    ExMsg.ConnectToPersistentSubscription.new(
      subscription_id: params.subscription,
      event_stream_id: params.stream,
      allowed_in_flight_messages: params.buffer_size
    )
  end

  defp ack_event(subscription_id, event_id) do
    ExMsg.PersistentSubscriptionAckEvents.new(
      subscription_id: subscription_id,
      processed_event_ids: [event_id]
    )
  end
end

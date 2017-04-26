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
      connection: connection,
      params: %{subscription: subscription, stream: stream, buffer_size: buffer_size},
      status: :initialized,
    }
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  def handle_cast(:connect, %{connection: connection, params: params} = state) do
    {:ok, response} = GenServer.call(connection, {:subscribe, self(), connect(params)})
    Logger.debug(fn -> "Successfully connected to persistent subscription #{inspect response}" end)
    {:noreply, %{state | status: :subscribed}}
  end

  def handle_cast({:ok, %ExMsg.PersistentSubscriptionStreamEventAppeared{}=e}, %{subscriber: subscriber, params: params} = state) do
    Logger.debug(fn -> "Persistent subscription #{inspect params.subscription} event appeared: #{inspect e}" end)
    send(subscriber, {:on_event, e.event, params.subscription})
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

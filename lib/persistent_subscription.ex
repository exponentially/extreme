defmodule Extreme.PersistentSubscription do
  use GenServer
  require Logger
  alias Extreme.Msg, as: ExMsg

  def start_link(connection, subscriber, params) do
    GenServer.start_link(__MODULE__, {connection, subscriber, params})
  end

  def init({connection, subscriber, {subscription, stream, buffer_size}}) do
    connect_params = %{subscription: subscription, stream: stream, buffer_size: buffer_size}
    GenServer.cast(self(), :connect)
    {:ok, %{subscriber: subscriber, connection: connection, connect_params: connect_params, status: :initialized}}
  end

  def handle_cast(:connect, %{connection: connection, connect_params: connect_params} = state) do
    {:ok, response} = GenServer.call(connection, {:subscribe, self(), connect(connect_params)})
    Logger.debug "Successfully connected to persistent subscription #{inspect response}"
    {:noreply, %{state | status: :subscribed}}
  end

  # def handle_cast(:read_and_stay_subscribed, state) do
  #   {:ok, subscription_confirmation} = GenServer.call state.connection, {:subscribe, self(), subscribe(state.read_params)}
  #   Logger.debug "Successfully subscribed to stream #{inspect subscription_confirmation}"
  #   GenServer.cast(self(), :read_events)
  #   read_until = subscription_confirmation.last_event_number + 1
  #   {:noreply, %{state | read_until: read_until, status: :reading_events}}
  # end
  #
  # def handle_cast(:read_events, %{read_params: %{from_event_number: from}, read_until: from}=state) do
  #   GenServer.cast(self(), :push_buffered_messages)
  #   {:noreply, %{state|status: :pushing_buffered}}
  # end
  # def handle_cast(:read_events, state) do
  #   {read_events, keep_reading} = read_events(state.read_params, state.read_until)
  #   state = case keep_reading do
  #     true  -> state
  #     false -> %{state|status: :pushing_buffered}
  #   end
  #   state = Extreme.execute(state.connection, read_events)
  #           |> process_response(state)
  #   {:noreply, state}
  # end
  # def handle_cast(:push_buffered_messages, state) do
  #   state.buffered_messages |> Enum.each(fn(e)-> send(state.subscriber, {:on_event, e}) end)
  #   send state.subscriber, :caught_up
  #   {:noreply, %{state|status: :subscribed, buffered_messages: []}}
  # end

  def handle_cast({:ok, %ExMsg.PersistentSubscriptionStreamEventAppeared{}=e}, %{subscriber: subscriber} = state) do
    send(subscriber, {:on_event, e.event})
    {:noreply, state}
  end

  defp connect(params) do
    IO.puts "params=#{inspect params}"
    ExMsg.ConnectToPersistentSubscription.new(
      subscription_id: params.subscription,
      event_stream_id: params.stream,
      allowed_in_flight_messages: params.buffer_size
    )
  end
end

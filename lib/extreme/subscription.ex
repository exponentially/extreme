defmodule Extreme.Subscription do
  use GenServer
  require Logger
  alias Extreme.RequestManager
  alias Extreme.Messages, as: Msg

  defmodule State do
    defstruct ~w(base_name correlation_id subscriber stream read_params status)a
  end

  def start_link(base_name, correlation_id, subscriber, stream, resolve_link_tos),
    do:
      GenServer.start_link(
        __MODULE__,
        {base_name, correlation_id, subscriber, stream, resolve_link_tos}
      )

  def process_push(server, fun),
    do: :ok = GenServer.cast(server, {:process_push, fun})

  def unsubscribe(server),
    do: GenServer.call(server, :unsubscribe)

  @impl true
  def init({base_name, correlation_id, subscriber, stream, resolve_link_tos}) do
    read_params = %{stream: stream, resolve_link_tos: resolve_link_tos}

    state = %State{
      base_name: base_name,
      correlation_id: correlation_id,
      subscriber: subscriber,
      read_params: read_params,
      status: :initialized
    }

    _subscribe(state)

    {:ok, state}
  end

  @impl true
  def handle_call(:unsubscribe, from, state) do
    message = Msg.UnsubscribeFromStream.new()
    spawn_link(fn ->
      state.base_name
      |> RequestManager.execute(message, state.correlation_id)
    end)
    Process.put(:reply_to, from)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:process_push, fun}, state) do
    case fun.() do
      {_auth, _correlation_id,
       %Msg.StreamEventAppeared{
         event: %Msg.ResolvedEvent{
           event: %Msg.EventRecord{event_type: "$streamDeleted"}
         }
       }} ->
        send(state.subscriber, {:extreme, :stream_deleted})
        Extreme.RequestManager._unregister_subscription(state.base_name, state.correlation_id)
        {:stop, {:shutdown, :stream_deleted}, state}

      {_auth, _correlation_id, %Msg.StreamEventAppeared{} = e} ->
        send(state.subscriber, {:on_event, e.event})
        {:noreply, state}

      {_auth, _correlation_id, %Msg.SubscriptionDropped{reason: :Unsubscribed}} ->
        Extreme.RequestManager._unregister_subscription(state.base_name, state.correlation_id)
        Process.get(:reply_to)
        |> GenServer.reply(:unsubscribed)
        {:stop, {:shutdown, :unsubscribed}, state}
    end
  end

  defp _subscribe(state) do
    message =
      Msg.SubscribeToStream.new(
        event_stream_id: state.read_params.stream,
        resolve_link_tos: state.read_params.resolve_link_tos
      )

    {:ok, subscription_confirmation} =
      state.base_name
      |> RequestManager.execute(message, state.correlation_id)

    Logger.debug(fn ->
      "Successfully subscribed to stream #{inspect(subscription_confirmation)}"
    end)

    :ok
  end
end

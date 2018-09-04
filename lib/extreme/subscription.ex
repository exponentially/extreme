defmodule Extreme.Subscription do
  use GenServer
  require Logger
  alias Extreme.RequestManager

  defmodule State do
    defstruct ~w(base_name correlation_id subscriber stream read_params status)a
  end

  def start_link(base_name, correlation_id, subscriber, stream, resolve_link_tos),
    do:
      GenServer.start_link(
        __MODULE__,
        {base_name, correlation_id, subscriber, stream, resolve_link_tos}
      )

  def process_push(server, fun) do
    :ok = GenServer.cast(server, {:process_push, fun})
  end

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
  def handle_cast({:process_push, fun}, state) do
    {_auth, _correlation_id, %Extreme.Messages.StreamEventAppeared{} = e} = fun.()
    send(state.subscriber, {:on_event, e.event})
    {:noreply, state}
  end

  defp _subscribe(state) do
    message =
      Extreme.Messages.SubscribeToStream.new(
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

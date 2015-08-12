defmodule Extreme.Subscription do
  use GenServer
  require Logger
  alias Extreme.Messages, as: ExMsg

  def start_link(connection, subscriber, read_params) do
    GenServer.start_link __MODULE__, {connection, subscriber, read_params}
  end

  def init({connection, subscriber, {stream, from_event_number, per_page, resolve_link_tos, require_master}}) do
    read_params = %{stream: stream, from_event_number: from_event_number, per_page: per_page, 
      resolve_link_tos: resolve_link_tos, require_master: require_master}
    GenServer.cast self, :read_events
    {:ok, %{subscriber: subscriber, connection: connection, read_params: read_params}}
  end

  def handle_cast(:read_events, state) do
    read_events = read_events(state.read_params)
    state = Extreme.execute(state.connection, read_events)
            |> process_response(state)
    {:noreply, state}
  end
  def handle_cast({:ok, %Extreme.Messages.StreamEventAppeared{}=e}, state) do
    send state.subscriber, {:on_event, e.event}
    {:noreply, state}
  end

  def process_response({:ok, %ExMsg.ReadStreamEventsCompleted{}=response}, state) do
    push_events response, state
    send_next_request response, state
  end

  defp push_events(response, state) do
    Enum.each response.events, fn e ->
      send state.subscriber, {:on_event, e}
    end
  end

  defp send_next_request(%{next_event_number: next_event_number, is_end_of_stream: false}, state) do
    GenServer.cast self, :read_events
    %{state|read_params: %{state.read_params|from_event_number: next_event_number}}
  end
  defp send_next_request(%{is_end_of_stream: true}, state) do
    subscription_confirmation = GenServer.call state.connection, {:subscribe, self, subscribe(state.read_params)}
    Logger.debug "Successfully subscribed to stream #{inspect subscription_confirmation}"
    state
  end

  defp read_events(params) do
    ExMsg.ReadStreamEvents.new(
      event_stream_id: params.stream,
      from_event_number: params.from_event_number,
      max_count: params.per_page,
      resolve_link_tos: params.resolve_link_tos,
      require_master: params.require_master
    )
  end

  defp subscribe(params) do
    ExMsg.SubscribeToStream.new(
      event_stream_id: params.stream, 
      resolve_link_tos: params.resolve_link_tos
    )
  end
end


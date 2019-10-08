defmodule Extreme.Listener do
  @moduledoc ~S"""
  TODO
  """
  defmacro __using__(_) do
    quote do
      use GenServer
      require Logger

      @default_read_per_page 500

      def child_spec([extreme, stream_name | opts]) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [extreme, stream_name, opts]}
        }
      end

      @doc """
      Starts Listener GenServer with `extreme` connection, for particular `stream_name`
      and options:

      * `:name` of listener process. Defaults to module name.
      * `:read_per_page` - number of events read in batches until all existing evets are processed. Defaults to 500
      * `:resolve_link_tos` - weather to resolve event links. Defaults to true.
      * `:require_master` - check if events are expected from master ES node. Defaults to false.
      * `:ack_timeout` - Wait time for ack message. Defaults to 5_000 ms.
      """
      def start_link(extreme, stream_name, opts \\ []) do
        {read_per_page, opts} = Keyword.pop(opts, :read_per_page, @default_read_per_page)
        {resolve_link_tos, opts} = Keyword.pop(opts, :resolve_link_tos, true)
        {require_master, opts} = Keyword.pop(opts, :require_master, false)
        {ack_timeout, opts} = Keyword.pop(opts, :ack_timeout, 5_000)
        opts = Keyword.put_new(opts, :name, __MODULE__)

        GenServer.start_link(
          __MODULE__,
          {extreme, stream_name, read_per_page, resolve_link_tos, require_master, ack_timeout},
          opts
        )
      end

      def unsubscribe(server), do: GenServer.call(server, :unsubscribe)

      @impl true
      def init(
            {extreme, stream_name, read_per_page, resolve_link_tos, require_master, ack_timeout}
          ) do
        state = %{
          extreme: extreme,
          subscription: nil,
          subscription_ref: nil,
          stream_name: stream_name,
          last_event: nil,
          mode: :init,
          per_page: read_per_page,
          resolve_link_tos: resolve_link_tos,
          require_master: require_master,
          ack_timeout: ack_timeout
        }

        GenServer.cast(self(), :subscribe)
        {:ok, state}
      end

      @impl true
      def handle_call(
            {:on_event, push},
            _from,
            %{subscription: subscription, mode: :live} = state
          )
          when not is_nil(subscription) do
        {:ok, event_number} = process_push(push, state.stream_name)
        {:reply, :ok, %{state | last_event: event_number}}
      end

      def handle_call(:unsubscribe, from, state) do
        true = Process.demonitor(state.subscription_ref)
        :unsubscribed = state.extreme.unsubscribe(state.subscription)
        {:reply, :ok, %{state | subscription: nil, subscription_ref: nil}}
      end

      @impl true
      def handle_cast(:subscribe, state) do
        {:ok, state} =
          case get_last_event(state.stream_name) do
            #            :from_now ->
            #              {:ok, %{last_event_number: last_event}} =
            #                Extreme.execute(state.event_store, _read_events_backward(state.stream_name))
            #
            #              _start_subscription(last_event, state)
            #
            #            {:patch, last_event, patch_until} ->
            #              start_patching(last_event, patch_until, state)
            #
            last_event ->
              _start_subscription(last_event, state)
          end

        {:noreply, state}
      end

      @impl true
      def handle_info({:DOWN, ref, :process, _pid, reason}, %{subscription_ref: ref} = state)
          when reason in [:pause, :done] do
        Logger.info("Subscription to stream #{state.stream_name} is #{inspect(reason)}")
        {:noreply, %{state | subscription: nil, subscription_ref: nil, mode: reason}}
      end

      def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
        reconnect_delay = 1_000
        Logger.warn("Subscription to EventStore is down. Will retry in #{reconnect_delay} ms.")
        :timer.sleep(reconnect_delay)
        GenServer.cast(self(), :subscribe)
        {:noreply, state}
      end

      def handle_info(:caught_up, %{subscription: subscription} = state)
          when not is_nil(subscription) do
        caught_up()
        {:noreply, state}
      end

      def handle_info(_msg, state), do: {:noreply, state}

      defp _start_subscription(last_event, state) do
        {:ok, subscription} =
          state.extreme.read_and_stay_subscribed(
            state.stream_name,
            self(),
            last_event + 1,
            state.per_page,
            state.resolve_link_tos,
            state.require_master,
            state.ack_timeout
          )

        ref = Process.monitor(subscription)

        Logger.info(fn ->
          "Listener subscribed to stream #{state.stream_name}. Start processing live events from event no: #{
            last_event + 1
          }"
        end)

        {:ok,
         %{
           state
           | subscription: subscription,
             subscription_ref: ref,
             last_event: last_event,
             mode: :live
         }}
      end

      defp _read_events_backward(stream, start \\ -1, count \\ 1) do
        Extreme.Messages.ReadStreamEventsBackward.new(
          event_stream_id: stream,
          from_event_number: start,
          max_count: count,
          resolve_link_tos: true,
          require_master: false
        )
      end

      def caught_up, do: Logger.debug(fn -> "We are up to date" end)
      def register_patching_start(_, _, _), do: {:error, :not_implemented}
      def patching_done(_), do: {:error, :not_implemented}
      def process_patch(_, _), do: {:error, :not_implemented}

      defoverridable caught_up: 0, register_patching_start: 3, patching_done: 1, process_patch: 2
    end
  end
end

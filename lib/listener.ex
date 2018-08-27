defmodule Extreme.Listener do
  @moduledoc ~S"""
  Since it is common on read side of system to read events and denormalize them,
  there is Extreme.Listener macro that hides noise from listener:

      defmodule MyApp.MyListener do
        use Extreme.Listener
        import MyApp.MyProcessor
      
        # returns last processed event by MyListener on stream_name,
        # -1 if none has been processed so far, or `:from_now` if you don't care for previous events
        defp get_last_event(stream_name), do: DB.get_last_event MyListener, stream_name
      
        defp process_push(push, stream_name) do
          #for indexed stream we need to follow push.link.event_number, otherwise push.event.event_number
          event_number = push.link.event_number
          DB.in_transaction fn ->
            Logger.info "Do some processing of event #{inspect push.event.event_type}"
            :ok = push.event.data
                   |> :erlang.binary_to_term
                   |> process_event(push.event.event_type)
            DB.ack_event(MyListener, stream_name, event_number)  
          end
          {:ok, event_number}
        end
    
        # This override is optional
        defp caught_up, do: Logger.debug("We are up to date. YEEEY!!!")
      end
      
      defmodule MyApp.MyProcessor do
        def process_event(data, "Elixir.MyApp.Events.PersonCreated") do
          Logger.debug "Doing something with #{inspect data}"
          :ok
        end
        def process_event(_, _), do: :ok # Just acknowledge events we are not interested in
      end

  Listener can be started manually but it is most common to place it in supervisor AFTER specifing Extreme:

      defmodule MyApp.Supervisor do
        use Supervisor
      
        def start_link, do: Supervisor.start_link __MODULE__, :ok
      
        @event_store MyApp.EventStore
        
        def init(:ok) do
          event_store_settings = Application.get_env :my_app, :event_store
      
          children = [
            worker(Extreme, [event_store_settings, [name: @event_store]]),
            worker(MyApp.MyListener, [@event_store, "my_indexed_stream", [name: MyListener, read_per_page: 1_000]]),
            # ... other workers / supervisors
          ]
          supervise children, strategy: :one_for_one
        end
      end

  Subscription can be paused:

      {:ok, last_event_number} = MyApp.MyListener.pause MyListener

  and resumed

      :ok = MyApp.MyListener.resume MyListener
  """
  defmacro __using__(_) do
    quote do
      use GenServer
      require Logger

      @default_read_per_page 500

      @doc """
      Starts Listener GenServer with `event_store` connection, for particular `stream_name`
      and options (`name` of process and `read_per_page` which defaults to 500.
      """
      def start_link(event_store, stream_name, opts \\ []),
        do:
          GenServer.start_link(
            __MODULE__,
            {event_store, stream_name, opts[:read_per_page] || @default_read_per_page},
            opts
          )

      def init({event_store, stream_name, read_per_page}) do
        state = %{
          event_store: event_store,
          last_event: nil,
          subscription: nil,
          subscription_ref: nil,
          stream_name: stream_name,
          mode: :init,
          patch_until: nil,
          per_page: read_per_page
        }

        GenServer.cast(self(), :subscribe)
        {:ok, state}
      end

      @doc """
      Pauses subscription with event store, returning {:ok, last_event_number}, where `last_event_number` is
      last event number from event store that was processed
      """
      def pause(server),
        do: GenServer.call(server, :pause)

      @doc """
      Resumes subscription with event store, returning :ok. get_last_event/1 from callback will be called, and its
      result will be used as starting event from which processing should continue.
      """
      def resume(server),
        do: GenServer.call(server, :resume)

      @doc """
      Pauses subscription with event store and runs events from `first_event` (defaults to 0)
      returning {:ok, last_event_number}, where `last_event_number` is
      last event number from event store that was processed.
      After all events upto `last_event_number` are processed subscription is resumed.
      """
      def patch(server, first_event \\ 0),
        do: GenServer.call(server, {:patch, first_event})

      def handle_cast(:subscribe, state) do
        {:ok, state} =
          case get_last_event(state.stream_name) do
            :from_now ->
              {:ok, %{last_event_number: last_event}} =
                Extreme.execute(state.event_store, _read_events_backward(state.stream_name))

              start_live_subscription(last_event, state)

            {:patch, last_event, patch_until} ->
              start_patching(last_event, patch_until, state)

            last_event ->
              start_live_subscription(last_event, state)
          end

        {:noreply, state}
      end

      defp start_live_subscription(last_event, state) do
        {:ok, subscription} =
          Extreme.read_and_stay_subscribed(
            state.event_store,
            self(),
            state.stream_name,
            last_event + 1,
            state.per_page
          )

        ref = Process.monitor(subscription)

        Logger.info(
          "Listener subscribed to stream #{state.stream_name}. Start processing live events from event no: #{
            last_event + 1
          }"
        )

        {:ok,
         %{
           state
           | subscription: subscription,
             subscription_ref: ref,
             last_event: last_event,
             mode: :live
         }}
      end

      defp start_patching(last_event, patch_until, state) do
        {:ok, subscription} =
          Extreme.read_and_stay_subscribed(
            state.event_store,
            self(),
            state.stream_name,
            last_event + 1,
            state.per_page
          )

        ref = Process.monitor(subscription)

        Logger.info(
          "Listener patching from stream #{state.stream_name} from event no: #{last_event + 1} until #{
            patch_until
          }"
        )

        {:ok,
         %{
           state
           | subscription: subscription,
             subscription_ref: ref,
             last_event: last_event,
             mode: :patch,
             patch_until: patch_until
         }}
      end

      def handle_call(:pause, _from, state) do
        true = Process.exit(state.subscription, :pause)
        Logger.info("Pausing listening stream #{state.stream_name}")

        {:reply, {:ok, state.last_event},
         %{state | subscription: nil, subscription_ref: nil, mode: :pause}}
      end

      def handle_call(:resume, _from, state) do
        GenServer.cast(self(), :subscribe)
        Logger.info("Resuming listening stream #{state.stream_name}")
        {:reply, :ok, state}
      end

      def handle_call({:patch, first_event}, _from, %{mode: mode} = state)
          when mode in [:pause, :live] do
        unless mode == :pause,
          do: true = Process.exit(state.subscription, :pause)

        :ok = register_patching_start(state.stream_name, first_event - 1, state.last_event)
        GenServer.cast(self(), :subscribe)

        {:reply, {:ok, state.last_event},
         %{state | subscription: nil, subscription_ref: nil, mode: :pause}}
      end

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

      def handle_info({:on_event, push}, %{subscription: subscription, mode: :live} = state)
          when not is_nil(subscription) do
        {:ok, event_number} = process_push(push, state.stream_name)
        {:noreply, %{state | last_event: event_number}}
      end

      def handle_info({:on_event, push}, %{subscription: subscription, mode: :patch} = state)
          when not is_nil(subscription) do
        {:ok, event_number} = process_patch(push, state.stream_name)

        state =
          if event_number == state.patch_until do
            :ok = patching_done(state.stream_name)
            GenServer.cast(self(), :subscribe)

            %{
              state
              | last_event: event_number,
                patch_until: nil,
                subscription: nil,
                subscription_ref: nil,
                mode: :done
            }
          else
            %{state | last_event: event_number}
          end

        {:noreply, state}
      end

      def handle_info(:caught_up, %{subscription: subscription} = state)
          when not is_nil(subscription) do
        caught_up()
        {:noreply, state}
      end

      def handle_info(_msg, state), do: {:noreply, state}

      defp _read_events_backward(stream, start \\ -1, count \\ 1) do
        Extreme.Msg.ReadStreamEventsBackward.new(
          event_stream_id: stream,
          from_event_number: start,
          max_count: count,
          resolve_link_tos: true,
          require_master: false
        )
      end

      def caught_up, do: Logger.debug("We are up to date")
      def register_patching_start(_, _, _), do: {:error, :not_implemented}
      def patching_done(_), do: {:error, :not_implemented}
      def process_patch(_, _), do: {:error, :not_implemented}

      defoverridable caught_up: 0, register_patching_start: 3, patching_done: 1, process_patch: 2
    end
  end
end

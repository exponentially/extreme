defmodule Extreme.FanoutListener do
  @moduledoc ~S"""
  Module that uses this listener will connect to stream of event store and wait for new events.
  In the contrast of Extreme.Listener which will first read existing events (starting from position x) and then
  keep listening new events.

  This is similar behavior as RabbitMQs fanout exchenge, hence the name.

  It's not uncommon situation to listen live events and propagate them (for example on web sockets).
  For that situation there is Extreme.FanoutListener macro that hides noise from listener:
  
      defmodule MyApp.MyFanoutListener do
        use Extreme.FanoutListener
        import MyApp.MyPusher
      
        defp process_push(push) do
          Logger.info "Forward to web socket event #{inspect push.event.event_type}"
          :ok = push.event.data
                 |> :erlang.binary_to_term
                 |> process_event(push.event.event_type)
        end
      end
      
      defmodule MyApp.MyPusher do
        def process_event(data, "Elixir.MyApp.Events.PersonCreated") do
          Logger.debug "Transform and push event with data: #{inspect data}"
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
            worker(MyApp.MyFanoutListener, [@event_store, "my_indexed_stream", [name: MyFanoutListener]]),
            # ... other workers / supervisors
          ]
          supervise children, strategy: :one_for_one
        end
      end
  """
  defmacro __using__(_) do
    quote do
      use GenServer

      def start_link(event_store, stream_name, opts \\ []), 
        do: GenServer.start_link __MODULE__, {event_store, stream_name}, opts
      
      def init({event_store, stream_name}) do
        state = %{ event_store: event_store, subscription_ref: nil, stream_name: stream_name }
        GenServer.cast self, :subscribe
        {:ok, state}
      end

	  def handle_cast(:subscribe, state) do
        {:ok, subscription} = Extreme.subscribe_to state.event_store, self, state.stream_name
        ref = Process.monitor subscription
        {:noreply, %{state|subscription_ref: ref}}
	  end
	  
	  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
	    GenServer.cast self, :subscribe
	    {:noreply, state}
	  end
      def handle_info({:on_event, push}, state) do
        :ok = process_push(push)
        {:noreply, state}
      end
      def handle_info(_msg, state), do: {:noreply, state}
    end
  end
end

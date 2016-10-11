defmodule Extreme.Listener do
  @moduledoc ~S"""
  Since it is common on read side of system to read events and denormalize them,
  there is Extreme.Listener macro that hides noise from listener:
  
      defmodule MyApp.MyListener do
        use Extreme.Listener
        import MyApp.MyProcessor
      
        # returns last processed event by MyListener on stream_name, -1 if none has been processed so far
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
            worker(MyApp.MyListener, [@event_store, "my_indexed_stream", [name: MyListener]]),
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
        state = %{ event_store: event_store, last_event: nil, subscription_ref: nil, stream_name: stream_name }
        GenServer.cast self, :subscribe
        {:ok, state}
      end

	  def handle_cast(:subscribe, state) do
	    last_event = get_last_event(state.stream_name)
	    {:ok, subscription} = Extreme.read_and_stay_subscribed state.event_store, self, state.stream_name, last_event + 1
	    ref = Process.monitor subscription
	    {:noreply, %{state|subscription_ref: ref, last_event: last_event}}
	  end
	  
	  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
	    GenServer.cast self, :subscribe
	    {:noreply, state}
	  end
      def handle_info({:on_event, push}, state) do
        {:ok, event_number} = process_push(push, state.stream_name)
        {:noreply, %{state|last_event: event_number}}
      end
      def handle_info(_msg, state), do: {:noreply, state}
    end
  end
end

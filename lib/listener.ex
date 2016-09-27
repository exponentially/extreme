defmodule Extreme.Listener do
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

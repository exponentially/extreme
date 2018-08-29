defmodule Extreme.RequestManager do
  use GenServer
  alias Extreme.{Configuration, Request, Response, Connection}

  defmodule State do
    defstruct ~w(base_name credentials requests)a
  end

  def _name(base_name), do: (to_string(base_name) <> ".RequestManager") |> String.to_atom()

  def _process_supervisor_name(base_name),
    do: (to_string(base_name) <> ".ProcessSupervisor") |> String.to_atom()

  def start_link(base_name, configuration),
    do: GenServer.start_link(__MODULE__, {base_name, configuration}, name: _name(base_name))

  @doc """
  Send IdentifyClient message to EventStore. Called when connection is established.
  """
  def identify_client(connection_name, base_name) do
    base_name
    |> _name()
    |> GenServer.cast({:identify_client, connection_name})
  end

  def send_heartbeat_response(base_name, correlation_id) do
    base_name
    |> _name()
    |> GenServer.cast({:send_heartbeat_response, correlation_id})
  end

  @doc """
  Processes server message as soon as it is completely received via tcp.
  This function is run in `connection` process.
  """
  def process_server_message(base_name, message) do
    :ok =
      base_name
      |> _name()
      |> GenServer.cast({:process_server_message, message})
  end

  @doc """
  Sends `message` as a response to pending request or as a push on subscription.
  `correlation_id` is used to find pending request/subscription.
  """
  def respond_with_server_message(base_name, correlation_id, response) do
    :ok =
      base_name
      |> _name()
      |> GenServer.cast({:respond_with_server_message, correlation_id, response})
  end

  def execute(base_name, message, correlation_id) do
    base_name
    |> _name()
    |> GenServer.call({:execute, correlation_id, message})
  end

  ## Server callbacks

  @impl true
  def init({base_name, configuration}) do
    {:ok,
     %State{
       base_name: base_name,
       credentials: Configuration.prepare_credentials(configuration),
       requests: %{}
     }}
  end

  @impl true
  def handle_call({:execute, correlation_id, message}, from, %State{} = state) do
    state = %State{state | requests: Map.put(state.requests, correlation_id, from)}

    state.base_name
    |> _process_supervisor_name()
    |> Task.Supervisor.start_child(fn ->
      {:ok, message} = Request.prepare(message, state.credentials, correlation_id)
      :ok = Connection.push(state.base_name, message)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:identify_client, connection_name}, %State{} = state) do
    {:ok, message} = Request.prepare(:identify_client, connection_name, state.credentials)

    :ok = Connection.push(state.base_name, message)
    {:noreply, state}
  end

  def handle_cast({:process_server_message, message}, %State{} = state) do
    state.base_name
    |> _process_supervisor_name()
    |> Task.Supervisor.start_child(fn ->
      message
      |> Response.parse()
      |> _respond_on(state.base_name)
    end)

    {:noreply, state}
  end

  def handle_cast({:send_heartbeat_response, correlation_id}, %State{} = state) do
    {:ok, message} = Request.prepare(:heartbeat_response, correlation_id)
    :ok = Connection.push(state.base_name, message)
    {:noreply, state}
  end

  def handle_cast({:respond_with_server_message, correlation_id, response}, %State{} = state) do
    case Map.get(state.requests, correlation_id) do
      nil ->
        _respond_to_subscription(response, correlation_id, state.subscriptions)
        state

      from ->
        :ok = GenServer.reply(from, response)
        requests = Map.delete(state.requests, correlation_id)
        %{state | requests: requests}
    end

    {:noreply, state}
  end

  ## Helper functions

  defp _respond_on({:client_identified, _correlation_id}, _),
    do: :ok

  defp _respond_on({:heartbeat_request, correlation_id}, base_name),
    do: :ok = send_heartbeat_response(base_name, correlation_id)

  defp _respond_on({:error, :not_authenticated, correlation_id}, base_name),
    do: :ok = respond_with_server_message(base_name, correlation_id, {:error, :not_authenticated})

  defp _respond_on({_auth, correlation_id, message}, base_name) do
    response = Response.reply(message, correlation_id)
    :ok = respond_with_server_message(base_name, correlation_id, response)
  end

  defp _respond_to_subscription(message, correlation_id, subscriptions) do
    # Logger.debug "Attempting to respond to subscription with message: #{inspect message}"
    case Map.get(subscriptions, correlation_id) do
      # Logger.error "Can't find correlation_id #{inspect correlation_id} for message #{inspect message}"
      nil ->
        :ok

      subscription ->
        response = Response.reply(message, correlation_id)
        GenServer.cast(subscription, response)
    end
  end
end

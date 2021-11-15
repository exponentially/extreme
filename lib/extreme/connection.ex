defmodule Extreme.Connection do
  use GenServer
  alias Extreme.{Configuration, RequestManager}
  alias Extreme.ConnectionImpl, as: Impl
  require Logger

  defmodule State do
    defstruct ~w(base_name socket received_data transport)a
  end

  def start_link(base_name, configuration),
    do: GenServer.start_link(__MODULE__, {base_name, configuration}, name: _name(base_name))

  def push(base_name, message) do
    :ok =
      base_name
      |> _name()
      |> GenServer.cast({:execute, message})
  end

  @doc """
  Opens a connection with EventStore. Returns `{:ok, socket}` on success or
  `{:error, :max_attempt_exceeded}` if connection wasn't made in `:max_attempts`
  provided in `configuration`. If not specified, `max_attempts` defaults to :infinity
  """
  def connect(host, port, configuration, attempt \\ 1) do
    configuration
    |> Keyword.get(:max_attempts, :infinity)
    |> case do
      :infinity -> true
      max when attempt <= max -> true
      _any -> false
    end
    |> if do
      if attempt > 1 do
        configuration
        |> Keyword.get(:reconnect_delay, 1_000)
        |> :timer.sleep()
      end

      _connect(host, port, configuration, attempt)
    else
      {:error, :max_attempt_exceeded}
    end
  end

  @impl true
  def init({base_name, configuration}) do
    GenServer.cast(self(), {:connect, configuration, 1})

    state = %State{
      base_name: base_name,
      received_data: "",
      transport: Keyword.get(configuration, :transport, :tcp)
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:connect, configuration, attempt}, state) do
    {:ok, host, port} = Configuration.get_node(configuration)

    case connect(host, port, configuration, attempt) do
      {:ok, socket} ->
        Logger.info(fn -> "Successfully connected to EventStore" end)

        :ok =
          configuration
          |> Configuration.get_connection_name()
          |> RequestManager.identify_client(state.base_name)

        {:noreply, %State{state | socket: socket}}

      error ->
        {:stop, error, state}
    end
  end

  def handle_cast({:execute, message}, %State{} = state) do
    case Impl.execute(message, state) do
      :ok -> {:noreply, state}
      other -> {:stop, {:execution_error, other}, state}
    end
  end

  @impl true
  def handle_info({:tcp, socket, pkg}, %State{socket: socket} = state) do
    {:ok, state} = Impl.receive_package(pkg, state)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state),
    do: {:stop, :tcp_closed, state}

  @impl true
  def terminate(reason, state) do
    Logger.warn("[Extreme] Connection terminated: #{inspect(reason)}")
    RequestManager.kill_all_subscriptions(state.base_name)
  end

  def _name(base_name), do: Module.concat(base_name, Connection)

  defp _connect(host, port, configuration, attempt) do
    Logger.info(fn -> "Connecting Extreme to #{host}:#{port}" end)

    transport_module =
      case Keyword.get(configuration, :transport, :tcp) do
        :tcp -> :gen_tcp
        :ssl -> :ssl
      end

    opts = Keyword.get(configuration, :transport_opts, []) ++ [:binary, active: :once]

    case transport_module.connect(host, port, opts) do
      {:ok, socket} ->
        {:ok, socket}

      reason ->
        Logger.warn(fn -> "Error connecting to EventStore: #{inspect(reason)}" end)
        connect(host, port, configuration, attempt + 1)
    end
  end
end

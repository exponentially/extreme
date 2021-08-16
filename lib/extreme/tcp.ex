defmodule Extreme.Tcp do
  @moduledoc """
  Set of functions for TCP communication.
  """

  require Logger

  @doc """
  Opens tcp connection with EventStore. Returns `{:ok, socket}` on success or
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

  defp _connect(host, port, configuration, attempt) do
    Logger.info(fn -> "Connecting Extreme to #{host}:#{port}" end)
    opts = [:binary, active: :once]

    host
    |> :gen_tcp.connect(port, opts)
    |> case do
      {:ok, socket} ->
        {:ok, socket}

      reason ->
        Logger.warn(fn -> "Error connecting to EventStore: #{inspect(reason)}" end)
        connect(host, port, configuration, attempt + 1)
    end
  end
end

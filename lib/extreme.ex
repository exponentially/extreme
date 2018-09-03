defmodule Extreme do
  @moduledoc """
  TODO
  """

  @type t :: module

  @doc false
  defmacro __using__(opts \\ []) do
    quote do
      @config unquote(opts[:config]) || []

      def start_link, do: Extreme.Supervisor.start_link(__MODULE__, @config)
      def start_link(config), do: Extreme.Supervisor.start_link(__MODULE__, config)

      def execute(message, correlation_id \\ Extreme.Tools.generate_uuid()),
        do: Extreme.RequestManager.execute(__MODULE__, message, correlation_id)
    end
  end

  @doc """
  TODO
  """
  @callback start_link(config :: Keyword.t(), opts :: Keyword.t()) ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}

  @doc """
  TODO
  """
  @callback execute(message :: term, correlation_id :: UUID.t()) :: term
end

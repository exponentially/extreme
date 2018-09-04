defmodule Extreme do
  @moduledoc """
  TODO
  """

  @type t :: module

  @doc false
  defmacro __using__(opts \\ []) do
    quote do
      @otp_app Keyword.get(unquote(opts), :otp_app, [])
      @config Application.get_env(@otp_app, __MODULE__)

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link, do: Extreme.Supervisor.start_link(__MODULE__, @config)
      def start_link(config), do: Extreme.Supervisor.start_link(__MODULE__, config)

      def execute(message, correlation_id \\ nil),
        do:
          Extreme.RequestManager.execute(
            __MODULE__,
            message,
            correlation_id || Extreme.Tools.generate_uuid()
          )

      def subscribe_to(stream, subscriber, resolve_link_tos \\ true)
          when is_binary(stream) and is_pid(subscriber) and is_boolean(resolve_link_tos),
          do:
            Extreme.RequestManager.subscribe_to(__MODULE__, stream, subscriber, resolve_link_tos)

      def unsubscribe(subscription) when is_pid(subscription),
        do: Extreme.Subscription.unsubscribe(subscription)
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

  @doc """
  TODO
  """
  @callback subscribe_to(stream :: String.t(), subscriber :: pid(), opts :: Keyword.t()) ::
              {:ok, pid}
end

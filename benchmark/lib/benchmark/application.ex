defmodule Extreme.Benchmark.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Extreme.Benchmark.StatsServer

  def start(_type, _args) do
    es_cfg = Application.get_env(:benchmark, :event_store)

    children = Enum.map(StatsServer.range(), fn i ->
      %{
        id: :"extreme_#{i}",
        start: {Extreme, :start_link, [es_cfg, [name: :"extreme_#{i}"]]},
        type: :supervisor
      }
    end)

    children = [
      %{
        id: DynamicSupervisor,
        start: {DynamicSupervisor, :start_link, [[name: :wroker_sup, strategy: :one_for_one]]},
        type: :supervisor
      },
      %{
        id: StatsServer,
        start: {StatsServer, :start_link, [[name: :stats]]}
      }
      | children
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Extreme.Benchmark.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

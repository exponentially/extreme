# This file will be removed. Extreme won't be started as application,
# but as part of supervision tree of host application

defmodule(ExtremeConn, do: use(Extreme))

defmodule App do
  use Application

  def start(_type, _args) do
    [{ExtremeConn, _config()}]
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  defp _config do
    [
      db_type: :node,
      host: "localhost",
      port: 1113,
      username: "admin",
      password: "changeit",
      connection_name: "extreme_dev"
    ]
  end
end

defmodule Extreme.Supervisor do
  use Supervisor

  def start_link(base_name, configuration, opts) do
    opts = Keyword.put(opts, :name, _name(base_name))
    Supervisor.start_link(__MODULE__, {base_name, configuration}, opts)
  end

  @impl true
  def init({base_name, configuration}) do
    [
      {Task.Supervisor, [name: Extreme.RequestManager._process_supervisor_name(base_name)]},
      %{
        id: RequestManager,
        start: {Extreme.RequestManager, :start_link, [base_name, configuration]}
      },
      %{
        id: Connection,
        start: {Extreme.Connection, :start_link, [base_name, configuration]}
      }
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp _name(base_name), do: (to_string(base_name) <> ".Supervisor") |> String.to_atom()
end

defmodule Extreme.RequestsSupervisor do
  use Supervisor

  def start_link(base_name) do
    Supervisor.start_link(__MODULE__, base_name, name: _name(base_name))
  end

  @impl true
  def init(base_name) do
    [
      {Registry, keys: :unique, name: _registry_name(base_name)},
      {Extreme.Requests, base_name}
    ]
    |> Supervisor.init(strategy: :rest_for_one)
  end

  defp _name(base_name), do: (to_string(base_name) <> ".RequestsSupervisor") |> String.to_atom()

  defp _registry_name(base_name),
    do: (to_string(base_name) <> ".RequestsRegistry") |> String.to_atom()
end

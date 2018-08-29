defmodule App do
  use Application

  def start(_type, _args) do
    config = Application.get_env(:extreme, :event_store)

    children = [
      %{
        id: Extreme,
        start: {Extreme, :start_link, [config]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule Extreme do
  def start_link(base_name \\ Extreme, config, opts \\ []) when is_list(config),
    do: Extreme.Supervisor.start_link(base_name, config, opts)

  def execute(base_name, message, correlation_id \\ Extreme.Tools.generate_uuid()),
    do: Extreme.RequestManager.execute(base_name, message, correlation_id)
end

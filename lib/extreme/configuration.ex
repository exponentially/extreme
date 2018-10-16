defmodule Extreme.Configuration do
  @moduledoc """
  Set of functions for retrieving configuration value with correct type
  """

  alias Extreme.{Tools, ClusterConnection}

  def get_node(configuration) do
    configuration
    |> _get_db_type
    |> _get_node(configuration)
  end

  @doc """
  Returns credentials part of EventStore request based on `:username` and `:password`
  fields in `configuration`. In any of those is not specified raises exception.
  """
  def prepare_credentials(configuration) do
    user = Keyword.fetch!(configuration, :username)
    pass = Keyword.fetch!(configuration, :password)

    user_len = byte_size(user)
    pass_len = byte_size(pass)

    <<user_len::size(8)>> <> user <> <<pass_len::size(8)>> <> pass
  end

  @doc """
  Returns `:connection_name` from `configuration` as binary.
  If one is not specified defaults to "Extreme".
  """
  def get_connection_name(configuration) do
    configuration
    |> Keyword.get(:connection_name, "Extreme")
    |> to_string()
  end

  # Returns `:db_type` value from `configuration` as `atom`.
  # If one is not specified, defaults to `:node`.
  defp _get_db_type(configuration) do
    configuration
    |> Keyword.get(:db_type, :node)
    |> Tools.cast_to_atom()
  end

  defp _get_node(:node, configuration),
    do: {:ok, _get_host(configuration), _get_port(configuration)}

  defp _get_node(:cluster, configuration) do
    gossip_timeout = Keyword.get(configuration, :gossip_timeout, 1_000)
    mode = Keyword.get(configuration, :mode, :write)

    configuration
    |> Keyword.fetch!(:nodes)
    |> ClusterConnection.gossip_with(gossip_timeout, mode)
  end

  def get_node(:cluster_dns, configuration) do
    {:ok, ips} =
      configuration
      |> _get_host
      |> :inet.getaddrs(:inet, 1_000)

    gossip_port =
      configuration
      |> Keyword.get(:port, 2113)
      |> Tools.cast_to_integer()

    gossip_timeout = Keyword.get(configuration, :gossip_timeout, 1_000)
    mode = Keyword.get(configuration, :mode, :write)

    ips
    |> Enum.map(fn ip ->
      %{host: to_string(:inet.ntoa(ip)), port: gossip_port}
    end)
    |> ClusterConnection.gossip_with(gossip_timeout, mode)
  end

  # Returns `:host` value from `configuration` as charlist.
  # If one is not specified raises exception.
  defp _get_host(configuration) do
    configuration
    |> Keyword.fetch!(:host)
    |> String.to_charlist()
  end

  # Returns `:port` value from `configuration` as `integer`.
  # If one is not specified raises exception.
  defp _get_port(configuration) do
    configuration
    |> Keyword.fetch!(:port)
    |> Tools.cast_to_integer()
  end
end

defmodule Extreme.ClusterConnection do
  require Logger

  def get_node(connection_settings) do
    nodes          = Keyword.fetch!(connection_settings, :nodes)
    gossip_timeout = Keyword.get(connection_settings, :gossip_timeout, 1_000)
    mode           = Keyword.get(connection_settings, :mode, :write)
    gossip_with nodes, gossip_timeout, mode
  end
  def get_node(:cluster_dns, connection_settings) do
    {:ok, ips}     = :inet.getaddrs(get_hostname(connection_settings), :inet, 1_000)
    gossip_timeout = Keyword.get(connection_settings, :gossip_timeout, 1_000)
    gossip_port    = Keyword.get(connection_settings, :port, 2113)
    mode           = Keyword.get(connection_settings, :mode, :write)
    nodes          = ips |> Enum.map(fn(ip)-> %{host: to_string(:inet.ntoa ip), port: gossip_port} end)
    gossip_with nodes, gossip_timeout, mode
  end

  def get_hostname(connection_settings) do
    hostname       = Keyword.fetch!(connection_settings, :host)
    cond do
      is_binary(hostname) -> to_char_list(hostname)
      true                -> hostname
    end
  end

  defp gossip_with([], _, _), do: {:error, :no_more_gossip_seeds}
  defp gossip_with([node|rest_nodes], gossip_timeout, mode) do
    url = "http://#{node.host}:#{node.port}/gossip?format=json"
    Logger.info "Gossip with #{url}"
    case HTTPoison.get(url, [], timeout: gossip_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
        |> choose_node(mode)
      error ->
        Logger.error "Error getting gossip: #{inspect error}"
        gossip_with rest_nodes, gossip_timeout, mode
    end
  end

  defp choose_node(%{"members" => members}, mode) do
    best_candidate = members
                      |> get_alive
                      |> inject_state_rank(mode)
                      |> remove_0_ranks
                      |> sort_by_rank
                      |> List.first
    Logger.info "We've chosen node: #{inspect best_candidate}"
    {:ok, best_candidate["externalTcpIp"], best_candidate["externalTcpPort"]}
  end

  defp get_alive(members),         do: Enum.filter(members, fn(m) -> m["isAlive"] end)
  defp inject_state_rank(members, mode), 
    do: Enum.map(members, fn(m) -> Map.merge m, %{state_rank: rank_state(m["state"], mode)} end)
  defp remove_0_ranks(members),    do: Enum.reject(members, &(&1.state_rank == 0))
  defp sort_by_rank(candidates),   do: Enum.sort(candidates, &(&1.state_rank < &2.state_rank))

  # Prefer Master when writing, but Slave for everything else (read)
  defp rank_state("Master", :write),    do: 1
  defp rank_state("Master", _),         do: 2
  defp rank_state("PreMaster", :write), do: 2
  defp rank_state("PreMaster", _),      do: 3
  defp rank_state("Slave", :write),     do: 3
  defp rank_state("Slave", _),          do: 1
  defp rank_state("Clone", _),          do: 4
  defp rank_state("CatchingUp", _),     do: 5
  defp rank_state("PreReplica", _),     do: 6
  defp rank_state("Unknown", _),        do: 7
  defp rank_state("Initializing", _),   do: 8

  defp rank_state("Manager", _),        do: 0
  defp rank_state("ShuttingDown", _),   do: 0
  defp rank_state("Shutdown", _),       do: 0
  defp rank_state(state, _),            do: Logger.warn("Unrecognized node state: #{state}"); 0
end

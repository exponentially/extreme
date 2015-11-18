defmodule Extreme.ClusterConnection do
  require Logger

  def get_node(connection_settings) do
    nodes = Keyword.fetch! connection_settings, :nodes
    gossip_with nodes
  end

  defp gossip_with([]), do: {:error, :no_more_gossip_seeds}
  defp gossip_with([node|rest_nodes]) do
    url = "http://#{node.host}:#{node.port}/gossip?format=json"
    Logger.info "Gossip with #{url}"
    case HTTPoison.get url, [], timeout: 1_000 do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
        |> choose_node
      error ->
        Logger.error "Error getting gossip: #{inspect error}"
        gossip_with rest_nodes
    end
  end

  defp choose_node(%{"members" => members}) do
    best_candidate = members
                      |> get_alive
                      |> inject_state_rank
                      |> remove_0_ranks
                      |> sort_by_rank
                      |> List.first
    Logger.info "We've chosen node: #{inspect best_candidate}"
    {:ok, best_candidate["externalTcpIp"], best_candidate["externalTcpPort"]}
  end

  defp get_alive(members), do: Enum.filter(members, fn(m) -> m["isAlive"] end)

  defp inject_state_rank(members), do: Enum.map(members, fn(m) -> Dict.merge m, %{state_rank: rank_state(m["state"])} end)

  defp remove_0_ranks(members), do: Enum.reject(members, &(&1.state_rank == 0))

  defp sort_by_rank(candidates), do: Enum.sort(candidates, &(&1.state_rank < &2.state_rank))

  defp rank_state("Master"), do: 1
  defp rank_state("PreMaster"), do: 2
  defp rank_state("Slave"), do: 3
  defp rank_state("Clone"), do: 4
  defp rank_state("CatchingUp"), do: 5
  defp rank_state("PreReplica"), do: 6
  defp rank_state("Unknown"), do: 7
  defp rank_state("Initializing"), do: 8

  defp rank_state("Manager"), do: 0
  defp rank_state("ShuttingDown"), do: 0
  defp rank_state("Shutdown"), do: 0
  defp rank_state(state), do: Logger.warn("Unrecognized node state: #{state}"); 0
end

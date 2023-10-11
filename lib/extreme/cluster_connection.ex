defmodule Extreme.ClusterConnection do
  @moduledoc """
  Finds node in EventStore cluster that connection should be established with.
  """

  require Logger

  def gossip_with(nodes, gossip_timeout, mode)

  def gossip_with([], _, _), do: {:error, :no_more_gossip_seeds}

  def gossip_with([node | rest_nodes], gossip_timeout, mode) do
    url = 'http://#{node.host}:#{node.port}/gossip?format=json'
    Logger.info("Gossip with #{url}")

    case :httpc.request(:get, {url, []}, [timeout: gossip_timeout], []) do
      {:ok, {{_version, 200, _status}, _headers, body}} ->
        body
        |> Jason.decode!()
        |> _choose_node(mode)

      error ->
        Logger.error("Error getting gossip: #{inspect(error)}")
        gossip_with(rest_nodes, gossip_timeout, mode)
    end
  end

  defp _choose_node(%{"members" => members}, mode) do
    best_candidate =
      members
      |> _get_alive
      |> _inject_state_rank(mode)
      |> _remove_0_ranks
      |> _sort_by_rank
      |> List.first()

    Logger.info("We've chosen node: #{inspect(best_candidate)}")
    {:ok, String.to_charlist(best_candidate["externalTcpIp"]), best_candidate["externalTcpPort"]}
  end

  defp _get_alive(members), do: Enum.filter(members, fn m -> m["isAlive"] end)

  defp _inject_state_rank(members, mode),
    do: Enum.map(members, fn m -> Map.merge(m, %{state_rank: _rank_state(m["state"], mode)}) end)

  defp _remove_0_ranks(members), do: Enum.reject(members, &(&1.state_rank == 0))

  defp _sort_by_rank(candidates), do: Enum.sort(candidates, &(&1.state_rank < &2.state_rank))

  # Prefer Master when writing, but Slave for everything else (read)
  defp _rank_state("Master", :write), do: 1
  defp _rank_state("PreMaster", :write), do: 2
  defp _rank_state("Slave", :write), do: 3
  defp _rank_state("Slave", _), do: 1
  defp _rank_state("Master", _), do: 2
  defp _rank_state("PreMaster", _), do: 3
  defp _rank_state("Clone", _), do: 4
  defp _rank_state("CatchingUp", _), do: 5
  defp _rank_state("PreReplica", _), do: 6
  defp _rank_state("Unknown", _), do: 7
  defp _rank_state("Initializing", _), do: 8

  defp _rank_state("Manager", _), do: 0
  defp _rank_state("ShuttingDown", _), do: 0
  defp _rank_state("Shutdown", _), do: 0
  defp _rank_state(state, _), do: Logger.warning("Unrecognized node state: #{state}")
end

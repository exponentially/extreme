defmodule Extreme.ClusterConnectionTest do
  use ExUnit.Case, async: true

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  describe "gossip_with/3" do
    test "returns master node ip and tcp port when configured for writing" do
      # vcr cassette file is customized after recording to return master as localhost
      use_cassette "gossip_with_clusters_existing_node" do
        assert {:ok, 'localhost', 1113} =
                 Extreme.ClusterConnection.gossip_with(
                   [%{host: "0.0.0.0", port: "2113"}],
                   20_000,
                   :write
                 )
      end
    end
  end
end

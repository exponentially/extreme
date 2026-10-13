defmodule Extreme.RequestManagerTest do
  use ExUnit.Case, async: false

  alias Extreme.RequestManager

  describe "subscription unregistered before it is confirmed" do
    setup do
      request_manager =
        TestConn
        |> RequestManager._name()
        |> Process.whereis()

      [request_manager: request_manager, correlation_id: Extreme.Tools.generate_uuid()]
    end

    test "request manager survives unregistering pending subscription", c do
      GenServer.cast(c.request_manager, {:prepare_subscription, c.correlation_id})
      GenServer.cast(c.request_manager, {:unregister_subscription, c.correlation_id})

      assert %{subscriptions: %{} = subscriptions} = :sys.get_state(c.request_manager)
      refute Map.has_key?(subscriptions, c.correlation_id)
      assert c.request_manager == TestConn |> RequestManager._name() |> Process.whereis()
    end

    test "request manager ignores late confirmation of unregistered subscription", c do
      subscription = spawn(fn -> :ok end)

      GenServer.cast(c.request_manager, {:prepare_subscription, c.correlation_id})
      GenServer.cast(c.request_manager, {:unregister_subscription, c.correlation_id})
      GenServer.cast(c.request_manager, {:confirm_subscription, c.correlation_id, subscription})

      assert %{subscriptions: %{} = subscriptions} = :sys.get_state(c.request_manager)
      refute Map.has_key?(subscriptions, c.correlation_id)
      assert c.request_manager == TestConn |> RequestManager._name() |> Process.whereis()
    end
  end
end

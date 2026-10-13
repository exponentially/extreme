defmodule Extreme.RequestManagerTest do
  use ExUnit.Case, async: false

  alias Extreme.RequestManager
  alias ExtremeTest.Helpers

  describe "request that is never answered" do
    defmodule(SilentConn, do: use(Extreme))

    setup do
      {:ok, _} =
        :extreme
        |> Application.get_env(TestConn)
        |> SilentConn.start_link()

      :pong = SilentConn.ping()

      SilentConn
      |> Extreme.Connection._name()
      |> :sys.suspend()

      request_manager =
        SilentConn
        |> RequestManager._name()
        |> Process.whereis()

      [request_manager: request_manager]
    end

    test "is forgotten once its call times out", c do
      correlation_id = Extreme.Tools.generate_uuid()

      assert {:timeout, _call} =
               catch_exit(SilentConn.execute(Helpers.write_events(), correlation_id, 100))

      assert :ok == _await_forgotten(c.request_manager, correlation_id, 50)
    end

    test "cancels its timeout once answered", c do
      correlation_id = Extreme.Tools.generate_uuid()

      task =
        Task.async(fn -> SilentConn.execute(Helpers.write_events(), correlation_id, 60_000) end)

      assert :ok == _await_pending(c.request_manager, correlation_id, 50)

      assert %{requests: %{^correlation_id => {_from, timer}}} =
               :sys.get_state(c.request_manager)

      assert is_integer(Process.read_timer(timer))

      SilentConn
      |> Extreme.Connection._name()
      |> :sys.resume()

      assert {:ok, %Extreme.Messages.WriteEventsCompleted{}} = Task.await(task)
      assert false == Process.read_timer(timer)
    end

    test "is kept when a stale timeout for its reused correlation id fires", c do
      correlation_id = Extreme.Tools.generate_uuid()
      Task.start(fn -> SilentConn.execute(Helpers.write_events(), correlation_id, :infinity) end)
      assert :ok == _await_pending(c.request_manager, correlation_id, 50)

      send(c.request_manager, {:forget_request, correlation_id, {self(), make_ref()}})

      assert %{requests: %{} = requests} = :sys.get_state(c.request_manager)
      assert Map.has_key?(requests, correlation_id)
    end
  end

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

  defp _await_pending(request_manager, correlation_id, attempts_left) do
    %{requests: requests} = :sys.get_state(request_manager)

    cond do
      Map.has_key?(requests, correlation_id) -> :ok
      attempts_left == 0 -> {:never_pending, correlation_id}
      true -> _retry_await_pending(request_manager, correlation_id, attempts_left)
    end
  end

  defp _retry_await_pending(request_manager, correlation_id, attempts_left) do
    Process.sleep(10)
    _await_pending(request_manager, correlation_id, attempts_left - 1)
  end

  defp _await_forgotten(request_manager, correlation_id, attempts_left) do
    %{requests: requests} = :sys.get_state(request_manager)

    cond do
      not Map.has_key?(requests, correlation_id) -> :ok
      attempts_left == 0 -> {:still_pending, correlation_id}
      true -> _retry_await_forgotten(request_manager, correlation_id, attempts_left)
    end
  end

  defp _retry_await_forgotten(request_manager, correlation_id, attempts_left) do
    Process.sleep(10)
    _await_forgotten(request_manager, correlation_id, attempts_left - 1)
  end
end

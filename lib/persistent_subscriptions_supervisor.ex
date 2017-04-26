defmodule Extreme.PersistentSubscriptionsSupervisor do
  use Supervisor

  def start_link(connection, opts \\ []) do
    Supervisor.start_link(__MODULE__, connection, opts)
  end

  def start_persistent_subscription(supervisor, subscriber, params) do
    Supervisor.start_child(supervisor, [subscriber, params])
  end

  def init(connection) do
    children = [
      worker(Extreme.PersistentSubscription, [connection], restart: :temporary),
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end

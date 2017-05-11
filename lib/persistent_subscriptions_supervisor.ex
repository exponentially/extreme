defmodule Extreme.PersistentSubscriptionsSupervisor do
  use Supervisor

  def start_link(connection_settings, opts \\ []) do
    Supervisor.start_link(__MODULE__, connection_settings, opts)
  end

  def start_persistent_subscription(supervisor, subscriber, params) do
    Supervisor.start_child(supervisor, [subscriber, params])
  end

  def init(connection_settings) do
    children = [
      worker(Extreme.PersistentSubscription, [connection_settings], restart: :temporary),
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end

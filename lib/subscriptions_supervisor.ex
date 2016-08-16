defmodule Extreme.SubscriptionsSupervisor do
  use Supervisor

  def start_link(connection, opts \\ []) do
    Supervisor.start_link(__MODULE__, connection, opts)
  end

  def start_subscription(supervisor, subscriber, read_params) do
    Supervisor.start_child(supervisor, [subscriber, read_params])
  end
  def start_subscription(supervisor, subscriber, stream, resolve_link_tos) do
    Supervisor.start_child(supervisor, [subscriber, stream, resolve_link_tos])
  end

  def init(connection) do
    children = [
      worker(Extreme.Subscription, [connection], restart: :temporary),
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end

defmodule Extreme.SubscriptionsSupervisor do
  use DynamicSupervisor
  alias Extreme.Subscription

  def _name(base_name),
    do: (to_string(base_name) <> ".SubscriptionsSupervisor") |> String.to_atom()

  def start_link(base_name),
    do: DynamicSupervisor.start_link(__MODULE__, :ok, name: _name(base_name))

  def init(:ok),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_subscription(base_name, correlation_id, subscriber, stream, resolve_link_tos) do
    base_name
    |> _name()
    |> DynamicSupervisor.start_child(%{
      id: Subscription,
      start:
        {Subscription, :start_link,
         [base_name, correlation_id, subscriber, stream, resolve_link_tos]}
    })
  end
end

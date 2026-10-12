defmodule Extreme.ReadingSubscriptionTest do
  use ExUnit.Case, async: true
  alias Extreme.ReadingSubscription
  alias Extreme.Messages, as: ExMsg

  describe "handle_cast(:push_buffered_messages, state)" do
    test "pushes only buffered events at or after the start" do
      {:ok, subscriber} = Subscriber.start_link()

      state = %ReadingSubscription.State{
        subscriber: subscriber,
        read_params: %{from_event_number: 5, ack_timeout: 1_000},
        buffered_messages: Enum.map([6, 5, 4], &_resolved_event/1)
      }

      assert {:noreply, %{status: :subscribed, buffered_messages: []}} =
               ReadingSubscription.handle_cast(:push_buffered_messages, state)

      assert_receive :caught_up
      assert [5, 6] == _pushed_numbers()
    end
  end

  defp _resolved_event(number),
    do: %ExMsg.ResolvedEvent{event: %ExMsg.EventRecord{event_number: number}}

  defp _pushed_numbers do
    receive do
      {:on_event, %ExMsg.ResolvedEvent{event: %ExMsg.EventRecord{event_number: number}}} ->
        [number | _pushed_numbers()]
    after
      0 -> []
    end
  end
end

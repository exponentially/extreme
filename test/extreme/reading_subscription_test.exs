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

  describe "reading a stream whose read replies no_stream" do
    test "retries the read while the subscription confirmed existing events" do
      base_name = _start_request_manager([:no_stream, {:events, [0, 1, 2]}])
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, _subscription} = _start_subscription(base_name, subscriber)

      for number <- [0, 1, 2],
          do:
            assert_receive(
              {:on_event, %ExMsg.ResolvedIndexedEvent{event: %{event_number: ^number}}}
            )

      assert_receive :caught_up
      refute_received {:extreme, :warn, :stream_soft_deleted, _stream}
    end

    test "gives every page its own retry budget" do
      no_streams = List.duplicate(:no_stream, 50)

      base_name =
        _start_request_manager(
          no_streams ++ [{:events, [0]}] ++ no_streams ++ [{:events, [1]}, {:events, [2]}]
        )

      {:ok, subscriber} = Subscriber.start_link()
      {:ok, _subscription} = _start_subscription(base_name, subscriber, 1)

      for number <- [0, 1, 2],
          do:
            assert_receive(
              {:on_event, %ExMsg.ResolvedIndexedEvent{event: %{event_number: ^number}}}
            )

      assert_receive :caught_up
      refute_received {:extreme, :warn, :stream_soft_deleted, _stream}
    end

    test "falls back to the soft-deleted warning once retries are exhausted" do
      base_name = _start_request_manager([])
      {:ok, subscriber} = Subscriber.start_link()
      {:ok, _subscription} = _start_subscription(base_name, subscriber)

      assert_receive {:extreme, :warn, :stream_soft_deleted, "soft-deleted"}
      assert_receive :caught_up
      assert 51 == FakeRequestManager.reads(base_name)
    end
  end

  defp _start_request_manager(read_replies) do
    base_name = :"#{__MODULE__}.Conn#{System.unique_integer([:positive])}"
    {:ok, _fake} = FakeRequestManager.start_link(base_name, read_replies)
    base_name
  end

  defp _start_subscription(base_name, subscriber, per_page \\ 10) do
    base_name
    |> ReadingSubscription.start_link(
      Extreme.Tools.generate_uuid(),
      subscriber,
      {"soft-deleted", 0, per_page, true, false, 1_000}
    )
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

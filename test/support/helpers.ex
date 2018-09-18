defmodule ExtremeTest.Events do
  defmodule(PersonCreated, do: defstruct([:name]))
  defmodule(PersonChangedName, do: defstruct([:name]))
end

defmodule ExtremeTest.Helpers do
  alias Extreme.Messages, as: ExMsg
  alias ExtremeTest.Events, as: Event
  require ExUnit.Assertions
  import ExUnit.Assertions

  def random_stream_name, do: "extreme_test-" <> to_string(UUID.uuid1())

  def write_events(
        stream \\ random_stream_name(),
        events \\ [
          %Event.PersonCreated{name: "Pera Peric"},
          %Event.PersonChangedName{name: "Zika"}
        ]
      ) do
    proto_events =
      Enum.map(events, fn event ->
        ExMsg.NewEvent.new(
          event_id: Extreme.Tools.generate_uuid(),
          event_type: to_string(event.__struct__),
          data_content_type: 0,
          metadata_content_type: 0,
          data: :erlang.term_to_binary(event),
          metadata: ""
        )
      end)

    ExMsg.WriteEvents.new(
      event_stream_id: stream,
      expected_version: -2,
      events: proto_events,
      require_master: false
    )
  end

  def delete_stream(stream, hard_delete) do
    ExMsg.DeleteStream.new(
      event_stream_id: stream,
      expected_version: -2,
      require_master: false,
      hard_delete: hard_delete
    )
  end

  def read_events(stream, start \\ 0, count \\ 1) do
    ExMsg.ReadStreamEvents.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: count,
      resolve_link_tos: true,
      require_master: false
    )
  end

  def read_events_backward(stream, start, count) do
    ExMsg.ReadStreamEventsBackward.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: count,
      resolve_link_tos: true,
      require_master: false
    )
  end

  def read_event(stream, position) do
    ExMsg.ReadEvent.new(
      event_stream_id: stream,
      event_number: position,
      resolve_link_tos: true,
      require_master: false
    )
  end

  def unsubscribe(extreme, subscription) do
    :unsubscribed = extreme.unsubscribe(subscription)
    assert_no_leaks(extreme)
  end

  def assert_no_leaks(base_name) do
    assert %{received_data: ""} = Extreme.Connection._name(base_name) |> :sys.get_state()

    %{requests: requests, subscriptions: subscriptions} =
      Extreme.RequestManager._name(base_name) |> :sys.get_state()

    assert Enum.empty?(requests)
    assert Enum.empty?(subscriptions)

    assert 0 ==
             Extreme.RequestManager._process_supervisor_name(base_name)
             |> Supervisor.which_children()
             |> Enum.count()

    assert 0 ==
             Extreme.SubscriptionsSupervisor._name(base_name)
             |> Supervisor.which_children()
             |> Enum.count()
  end
end

defmodule ExtremeTest.Events do
  defmodule(PersonCreated, do: defstruct([:name]))
  defmodule(PersonChangedName, do: defstruct([:name]))
end

defmodule ExtremeTest.Helpers do
  alias Extreme.Messages, as: ExMsg
  alias ExtremeTest.Events, as: Event

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
end

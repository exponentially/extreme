defmodule ExtremeTest.Events do
  defmodule(PersonCreated, do: defstruct([:name]))
  defmodule(PersonChangedName, do: defstruct([:name]))
  defmodule(SlowProcessingEventHappened, do: defstruct([:sleep]))
  defmodule(BigNumberAdded, do: defstruct([:number]))
  defmodule(BigNumberMapAdded, do: defstruct([:number_map]))
  defmodule(StopOnThisOne, do: defstruct([:times]))
end

defmodule ExtremeTest.Helpers do
  alias Extreme.Messages, as: ExMsg
  alias ExtremeTest.Events, as: Event
  require Logger
  import ExUnit.Assertions

  def random_stream_name, do: "extreme_test-" <> uuid_string()

  @doc "A fresh `Extreme.Tools.generate_uuid/0` id in its 8-4-4-4-12 string form."
  def uuid_string do
    <<a::binary-4, b::binary-2, c::binary-2, d::binary-2, e::binary-6>> =
      Extreme.Tools.generate_uuid()

    [a, b, c, d, e]
    |> Enum.map(&Base.encode16(&1, case: :lower))
    |> Enum.join("-")
  end

  @doc "Recorded gossip response with every member advertising `external_tcp_port`."
  def gossip_response(external_tcp_port) do
    "fixture/vcr_cassettes/gossip_with_clusters_existing_node.json"
    |> File.read!()
    |> Jason.decode!()
    |> List.first()
    |> get_in(["response", "body"])
    |> Jason.decode!()
    |> Map.update!("members", fn members ->
      Enum.map(members, &Map.put(&1, "externalTcpPort", external_tcp_port))
    end)
    |> Jason.encode!()
  end

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

  def write_json_events(
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
          data_content_type: 1,
          metadata_content_type: 1,
          data: Jason.encode!(Map.from_struct(event)),
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

  # ESDB acks a write to a soft-deleted stream before indexing the metadata event that undeletes it.
  def read_when_undeleted(extreme, stream, attempts \\ 50) do
    stream
    |> read_events(0, 2)
    |> extreme.execute()
    |> case do
      {:error, :no_stream, _response} when attempts > 1 ->
        Process.sleep(20)
        read_when_undeleted(extreme, stream, attempts - 1)

      response ->
        response
    end
  end

  def unsubscribe(extreme, subscription) do
    :ok = extreme.unsubscribe(subscription)

    assert_no_leaks(extreme)
  end

  def assert_no_leaks(base_name) do
    # it takes some time for unsubscribe response from ES
    Process.sleep(50)

    assert(
      %{received_data: ""} = Extreme.Connection._name(base_name) |> :sys.get_state(),
      "There is unprocessed received data in connection process"
    )

    %{requests: requests, subscriptions: subscriptions} =
      Extreme.RequestManager._name(base_name) |> :sys.get_state()

    unless Enum.empty?(requests),
      do: Logger.error("Requests registered in RequestManager: #{inspect(requests)}")

    assert Enum.empty?(requests),
           "There are #{Enum.count(requests)} waiting requests in request manager"

    unless Enum.empty?(subscriptions),
      do: Logger.error("Subscriptions registered in RequestManager: #{inspect(subscriptions)}")

    assert Enum.empty?(subscriptions),
           "There are #{Enum.count(subscriptions)} opened subscriptions in request manager"

    children_count =
      Extreme.RequestManager._process_supervisor_name(base_name)
      |> Supervisor.which_children()
      |> Enum.count()

    assert 0 == children_count, "There are #{children_count} hanging request processes"

    children_count =
      Extreme.SubscriptionsSupervisor._name(base_name)
      |> Supervisor.which_children()
      |> Enum.count()

    assert 0 == children_count, "There are #{children_count} hanging subscription processes"
  end

  def create_persistent_subscription(stream, group) do
    ExMsg.CreatePersistentSubscription.new(
      subscription_group_name: group,
      event_stream_id: stream,
      resolve_link_tos: true,
      start_from: 0,
      message_timeout_milliseconds: 500,
      record_statistics: false,
      live_buffer_size: 500,
      read_batch_size: 20,
      buffer_size: 500,
      max_retry_count: 10,
      prefer_round_robin: true,
      checkpoint_after_time: 1_000,
      checkpoint_max_count: 500,
      checkpoint_min_count: 1,
      subscriber_max_count: 1
    )
  end

  def delete_persistent_subscription(stream, group) do
    ExMsg.DeletePersistentSubscription.new(
      subscription_group_name: group,
      event_stream_id: stream
    )
  end
end

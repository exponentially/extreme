defmodule Extreme.MessageCommandReader.Test do
  use ExUnit.Case

  @tcp_commands  Extreme.MessageCommandReader.tcp_commands
  @all_available Extreme.MessageCommandReader.available_proto_modules

  @all_protos [Extreme.Messages.ConnectToPersistentSubscription,
     Extreme.Messages.CreatePersistentSubscription,
     Extreme.Messages.CreatePersistentSubscriptionCompleted,
     Extreme.Messages.DeletePersistentSubscription,
     Extreme.Messages.DeletePersistentSubscriptionCompleted,
     Extreme.Messages.DeleteStream, Extreme.Messages.DeleteStreamCompleted,
     Extreme.Messages.NotHandled, Extreme.Messages.PersistentSubscriptionAckEvents,
     Extreme.Messages.PersistentSubscriptionConfirmation,
     Extreme.Messages.PersistentSubscriptionNakEvents,
     Extreme.Messages.PersistentSubscriptionStreamEventAppeared,
     Extreme.Messages.ReadEvent, Extreme.Messages.ReadEventCompleted,
     Extreme.Messages.ScavengeDatabase, Extreme.Messages.ScavengeDatabaseCompleted,
     Extreme.Messages.StreamEventAppeared, Extreme.Messages.SubscribeToStream,
     Extreme.Messages.SubscriptionConfirmation,
     Extreme.Messages.SubscriptionDropped, Extreme.Messages.TransactionCommit,
     Extreme.Messages.TransactionCommitCompleted, Extreme.Messages.TransactionStart,
     Extreme.Messages.TransactionStartCompleted, Extreme.Messages.TransactionWrite,
     Extreme.Messages.TransactionWriteCompleted,
     Extreme.Messages.UnsubscribeFromStream,
     Extreme.Messages.UpdatePersistentSubscription,
     Extreme.Messages.UpdatePersistentSubscriptionCompleted,
     Extreme.Messages.WriteEvents, Extreme.Messages.WriteEventsCompleted]

  @all_left_protos [Extreme.Messages.EventRecord, Extreme.Messages.NewEvent,
     Extreme.Messages.NotHandled.MasterInfo, Extreme.Messages.ReadAllEvents,
     Extreme.Messages.ReadAllEventsCompleted, Extreme.Messages.ReadStreamEvents,
     Extreme.Messages.ReadStreamEventsCompleted, Extreme.Messages.ResolvedEvent,
     Extreme.Messages.ResolvedIndexedEvent]

  @non_mapped_commands [{:heartbeat_request_command, false, 1},
     {:heartbeat_response_command, false, 2}, {:ping, false, 3}, {:pong, false, 4},
     {:prepare_ack, false, 5}, {:commit_ack, false, 6},
     {:slave_assignment, false, 7}, {:clone_assignment, false, 8},
     {:subscribe_replica, false, 16}, {:replica_log_position_ack, false, 17},
     {:create_chunk, false, 18}, {:raw_chunk_bulk, false, 19},
     {:data_chunk_bulk, false, 20}, {:replica_subscription_retry, false, 21},
     {:replica_subscribed, false, 22},
     {:read_stream_events_forward, false, 178},
     {:read_stream_events_forward_completed, false, 179},
     {:read_stream_events_backward, false, 180},
     {:read_stream_events_backward_completed, false, 181},
     {:read_all_events_forward, false, 182},
     {:read_all_events_forward_completed, false, 183},
     {:read_all_events_backward, false, 184},
     {:read_all_events_backward_completed, false, 185},
     {:bad_request, false, 240},
     {:authenticate, false, 242}, {:authenticated, false, 243},
     {:not_authenticated, false, 244}]


  @mapped_commands [{:write_events, Extreme.Messages.WriteEvents, 130},
     {:write_events_completed, Extreme.Messages.WriteEventsCompleted, 131},
     {:transaction_start, Extreme.Messages.TransactionStart, 132},
     {:transaction_start_completed, Extreme.Messages.TransactionStartCompleted,
      133}, {:transaction_write, Extreme.Messages.TransactionWrite, 134},
     {:transaction_write_completed, Extreme.Messages.TransactionWriteCompleted,
      135}, {:transaction_commit, Extreme.Messages.TransactionCommit, 136},
     {:transaction_commit_completed, Extreme.Messages.TransactionCommitCompleted,
      137}, {:delete_stream, Extreme.Messages.DeleteStream, 138},
     {:delete_stream_completed, Extreme.Messages.DeleteStreamCompleted, 139},
     {:read_event, Extreme.Messages.ReadEvent, 176},
     {:read_event_completed, Extreme.Messages.ReadEventCompleted, 177},
     {:subscribe_to_stream, Extreme.Messages.SubscribeToStream, 192},
     {:subscription_confirmation, Extreme.Messages.SubscriptionConfirmation, 193},
     {:stream_event_appeared, Extreme.Messages.StreamEventAppeared, 194},
     {:unsubscribe_from_stream, Extreme.Messages.UnsubscribeFromStream, 195},
     {:subscription_dropped, Extreme.Messages.SubscriptionDropped, 196},
     {:connect_to_persistent_subscription,
      Extreme.Messages.ConnectToPersistentSubscription, 197},
     {:persistent_subscription_confirmation,
      Extreme.Messages.PersistentSubscriptionConfirmation, 198},
     {:persistent_subscription_stream_event_appeared,
      Extreme.Messages.PersistentSubscriptionStreamEventAppeared, 199},
     {:create_persistent_subscription,
      Extreme.Messages.CreatePersistentSubscription, 200},
     {:create_persistent_subscription_completed,
      Extreme.Messages.CreatePersistentSubscriptionCompleted, 201},
     {:delete_persistent_subscription,
      Extreme.Messages.DeletePersistentSubscription, 202},
     {:delete_persistent_subscription_completed,
      Extreme.Messages.DeletePersistentSubscriptionCompleted, 203},
     {:persistent_subscription_ack_events,
      Extreme.Messages.PersistentSubscriptionAckEvents, 204},
     {:persistent_subscription_nak_events,
      Extreme.Messages.PersistentSubscriptionNakEvents, 205},
     {:update_persistent_subscription,
      Extreme.Messages.UpdatePersistentSubscription, 206},
     {:update_persistent_subscription_completed,
      Extreme.Messages.UpdatePersistentSubscriptionCompleted, 207},
     {:scavenge_database, Extreme.Messages.ScavengeDatabase, 208},
     {:scavenge_database_completed, Extreme.Messages.ScavengeDatabaseCompleted,
      209}, {:not_handled, Extreme.Messages.NotHandled, 241}]
  def check(pos, el) do
    assert @tcp_commands |> Enum.at(pos) == el
  end

  test "reads correctly" do
    check 0,  {:heartbeat_request_command, false, 1}
    check 1,  {:heartbeat_response_command, false, 2}
    check 2,  {:ping, false, 3}
    check 18, {:transaction_start_completed, Extreme.Messages.TransactionStartCompleted, 133}
    check -1, {:not_authenticated, false, 244}
  end

  test "has correct number of recognized protos" do
    assert @tcp_commands
    |> Enum.reject(fn({_,b,_})-> b == false end)
    |> Enum.count == 31

    sorted_commands = @tcp_commands
    |> Enum.reject(fn({_,b,_})-> b == false end)
    |> Enum.map(fn({_,b,_})-> b end)
    |> Enum.sort(fn(a,b)-> Atom.to_string(a) < Atom.to_string(b) end)

    assert sorted_commands == @all_protos
    assert (@all_available -- sorted_commands) == @all_left_protos
  end

  test "has correct number of non-proto commands" do
    filter = fn(list)->
      list |> Enum.filter(fn({_,b,_})-> b == false end)
    end
    assert filter.(@tcp_commands) == @non_mapped_commands
    assert filter.(@tcp_commands) |> Enum.count == 27
  end
end

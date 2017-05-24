defmodule Extreme.MessageResolverNew do
  # Extreme.MessageCommandReader.tcp_commands |> Enum.each(fn(x)-> IO.inspect x end)
  all  = [
    {:heartbeat_request_command, false, 1},
    {:heartbeat_response_command, false, 2},
    {:ping, false, 3},
    {:pong, false, 4},
    {:prepare_ack, false, 5},
    {:commit_ack, false, 6},
    {:slave_assignment, false, 7},
    {:clone_assignment, false, 8},
    {:subscribe_replica, false, 16},
    {:replica_log_position_ack, false, 17},
    {:create_chunk, false, 18},
    {:raw_chunk_bulk, false, 19},
    {:data_chunk_bulk, false, 20},
    {:replica_subscription_retry, false, 21},
    {:replica_subscribed, false, 22},
    {:write_events, Extreme.Messages.WriteEvents, 130},
    {:write_events_completed, Extreme.Messages.WriteEventsCompleted, 131},
    {:transaction_start, Extreme.Messages.TransactionStart, 132},
    {:transaction_start_completed, Extreme.Messages.TransactionStartCompleted, 133},
    {:transaction_write, Extreme.Messages.TransactionWrite, 134},
    {:transaction_write_completed, Extreme.Messages.TransactionWriteCompleted, 135},
    {:transaction_commit, Extreme.Messages.TransactionCommit, 136},
    {:transaction_commit_completed, Extreme.Messages.TransactionCommitCompleted, 137},
    {:delete_stream, Extreme.Messages.DeleteStream, 138},
    {:delete_stream_completed, Extreme.Messages.DeleteStreamCompleted, 139},
    {:read_event, Extreme.Messages.ReadEvent, 176},
    {:read_event_completed, Extreme.Messages.ReadEventCompleted, 177},
    {:read_stream_events_forward, false, 178},
    {:read_stream_events_forward_completed, false, 179},
    {:read_stream_events_backward, false, 180},
    {:read_stream_events_backward_completed, false, 181},
    {:read_all_events_forward, false, 182},
    {:read_all_events_forward_completed, false, 183},
    {:read_all_events_backward, false, 184},
    {:read_all_events_backward_completed, false, 185},
    {:subscribe_to_stream, Extreme.Messages.SubscribeToStream, 192},
    {:subscription_confirmation, Extreme.Messages.SubscriptionConfirmation, 193},
    {:stream_event_appeared, Extreme.Messages.StreamEventAppeared, 194},
    {:unsubscribe_from_stream, Extreme.Messages.UnsubscribeFromStream, 195},
    {:subscription_dropped, Extreme.Messages.SubscriptionDropped, 196},
    {:connect_to_persistent_subscription, Extreme.Messages.ConnectToPersistentSubscription, 197},
    {:persistent_subscription_confirmation, Extreme.Messages.PersistentSubscriptionConfirmation, 198},
    {:persistent_subscription_stream_event_appeared, Extreme.Messages.PersistentSubscriptionStreamEventAppeared, 199},
    {:create_persistent_subscription, Extreme.Messages.CreatePersistentSubscription, 200},
    {:create_persistent_subscription_completed, Extreme.Messages.CreatePersistentSubscriptionCompleted, 201},
    {:delete_persistent_subscription, Extreme.Messages.DeletePersistentSubscription, 202},
    {:delete_persistent_subscription_completed, Extreme.Messages.DeletePersistentSubscriptionCompleted, 203},
    {:persistent_subscription_ack_events, Extreme.Messages.PersistentSubscriptionAckEvents, 204},
    {:persistent_subscription_nak_events, Extreme.Messages.PersistentSubscriptionNakEvents, 205},
    {:update_persistent_subscription, Extreme.Messages.UpdatePersistentSubscription, 206},
    {:update_persistent_subscription_completed, Extreme.Messages.UpdatePersistentSubscriptionCompleted, 207},
    {:scavenge_database, Extreme.Messages.ScavengeDatabase, 208},
    {:scavenge_database_completed, Extreme.Messages.ScavengeDatabaseCompleted, 209},
    {:bad_request, false, 240},
    {:not_handled, Extreme.Messages.NotHandled, 241},
    {:authenticate, false, 242},
    {:authenticated, false, 243},
    {:not_authenticated, false, 244}
  ]
  plain = all |> Enum.filter(fn({_,b,_})-> b == false end)
  proto = all |> Enum.filter(fn({_,b,_})-> b != false end)
  special = [
    {:read_stream_events_forward, Extreme.Messages.ReadStreamEvents, 178},
    {:read_stream_events_forward_completed, Extreme.Messages.ReadStreamEventsCompleted, 179},
    {:read_stream_events_backward, Extreme.Messages.ReadStreamEvents, 180},
    {:read_stream_events_backward_completed, Extreme.Messages.ReadStreamEventsCompleted, 181},
    {:read_all_events_forward, Extreme.Messages.ReadAllEvents, 182},
    {:read_all_events_forward_completed, Extreme.Messages.ReadAllEventsCompleted, 183},
    {:read_all_events_backward, Extreme.Messages.ReadAllEvents, 184},
    {:read_all_events_backward_completed, Extreme.Messages.ReadAllEventsCompleted, 185},
  ]

  # first generate all decode functions (bit -> human)
  for {type, proto_msg, bit} <- (proto ++ special) do
    def decode_cmd(unquote(bit)) do
      unquote(proto_msg)
    end
  end

  for {type, proto_msg, bit} <- plain do
    unless Extreme.MessageCommandReader.special?(type) do
      def decode_cmd(unquote(bit)) do
        unquote(type)
      end
    end
  end

  # now reverse (human -> bit)
  for {type, proto_msg, bit} <- plain do
    def encode_cmd(unquote(type)) do
      unquote(bit)
    end
  end
  for {type, proto_msg, bit} <- proto do
    def encode_cmd(unquote(proto_msg)) do
      unquote(bit)
    end
  end
end

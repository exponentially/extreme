defmodule Extreme.MessageResolver do
  # https://github.com/EventStore/EventStore/blob/master/src/EventStore.ClientAPI/SystemData/TcpCommand.cs
  alias Extreme.Messages, as: Msg

  ## Encode

  def encode_cmd(:heartbeat_response), do: 0x02
  def encode_cmd(:ping), do: 0x03

  # def encode_cmd(:prepare_ack), do: 0x05
  # def encode_cmd(:commit_ack), do: 0x06
  # def encode_cmd(:slave_assignment), do: 0x07
  # def encode_cmd(0x08), do: :clone_assignment
  # def encode_cmd(:subscribe_replica), do: 0x10
  # def encode_cmd(:replica_log_position_ack), do: 0x11
  # def encode_cmd(:create_chunk), do: 0x12
  # def encode_cmd(:raw_chunk_bulk), do: 0x13
  # def encode_cmd(:data_chunk_bulk), do: 0x14
  # def encode_cmd(:replica_subscription_retry), do: 0x15
  # def encode_cmd(:replica_subscribed), do: 0x16
  # def encode_cmd(:create_stream), do: 0x80
  # def encode_cmd(:create_stream_completed), do: 0x81

  # def decode_cmd(0x82), do: Msg.WriteEvents
  # def encode_cmd(Msg.WriteEventsCompleted), do: 0x83

  def encode_cmd(Msg.WriteEvents), do: 0x82
  def encode_cmd(Msg.TransactionStart), do: 0x84
  def encode_cmd(Msg.TransactionWrite), do: 0x86
  def encode_cmd(Msg.TransactionCommit), do: 0x88
  def encode_cmd(Msg.DeleteStream), do: 0x8A

  def encode_cmd(Msg.ReadEvent), do: 0xB0
  def encode_cmd(Msg.ReadStreamEvents), do: 0xB2
  def encode_cmd(Msg.ReadStreamEventsBackward), do: 0xB4
  def encode_cmd(:read_all_events_forward), do: 0xB6
  def encode_cmd(:read_all_events_forward_completed), do: 0xB7
  def encode_cmd(:read_all_events_backward), do: 0xB8
  def encode_cmd(:read_all_events_backward_completed), do: 0xB9

  def encode_cmd(Msg.SubscribeToStream), do: 0xC0
  def encode_cmd(:unsubscribe_from_stream), do: 0xC3
  def encode_cmd(Msg.ConnectToPersistentSubscription), do: 0xC5
  def encode_cmd(Msg.CreatePersistentSubscription), do: 0xC8
  def encode_cmd(Msg.DeletePersistentSubscription), do: 0xCA
  def encode_cmd(Msg.DeletePersistentSubscriptionCompleted), do: 0xCB
  def encode_cmd(Msg.PersistentSubscriptionAckEvents), do: 0xCC
  def encode_cmd(Msg.PersistentSubscriptionNakEvents), do: 0xCD
  def encode_cmd(:update_persistent_subscription), do: 0xCE
  def encode_cmd(:update_persistent_subscription_completed), do: 0xCF

  def encode_cmd(:scavenge_database), do: 0xD0
  def encode_cmd(:scavenge_database_completed), do: 0xD1

  def encode_cmd(:not_handled), do: 0xF1
  def encode_cmd(:authenticate), do: 0xF2
  def encode_cmd(:authenticated), do: 0xF3
  def encode_cmd(Msg.IdentifyClient), do: 0xF5

  ## Decode

  def decode_cmd(0x01), do: :heartbeat_request_command
  def decode_cmd(0x04), do: :pong

  def decode_cmd(0x83), do: Msg.WriteEventsCompleted
  def decode_cmd(0x85), do: Msg.TransactionStartCompleted
  def decode_cmd(0x87), do: Msg.TransactionWriteCompleted
  def decode_cmd(0x89), do: Msg.TransactionCommitCompleted
  def decode_cmd(0x8B), do: Msg.DeleteStreamCompleted

  def decode_cmd(0xB1), do: Msg.ReadEventCompleted
  def decode_cmd(0xB3), do: Msg.ReadStreamEventsCompleted
  def decode_cmd(0xB5), do: Msg.ReadStreamEventsCompleted

  def decode_cmd(0xC1), do: Msg.SubscriptionConfirmation
  def decode_cmd(0xC2), do: Msg.StreamEventAppeared
  def decode_cmd(0xC4), do: Msg.SubscriptionDropped

  def decode_cmd(0xC6), do: Msg.PersistentSubscriptionConfirmation
  def decode_cmd(0xC7), do: Msg.PersistentSubscriptionStreamEventAppeared

  def decode_cmd(0xC9), do: Msg.CreatePersistentSubscriptionCompleted
  def decode_cmd(0xCB), do: Msg.DeletePersistentSubscriptionCompleted

  def decode_cmd(0xF0), do: :bad_request
  def decode_cmd(0xF4), do: :not_authenticated
  def decode_cmd(0xF6), do: :client_identified
end

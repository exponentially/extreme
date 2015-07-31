defmodule Extreme.MessageResolver do
    alias Extreme.Messages, as: Msg
	# _Hartbeat command
	def decode_cmd(0x01), do: :heartbeat_request_command
	def encode_cmd(:heartbeat_response), do: 0x02
	# _Ping command
	def encode_cmd(:ping), do: 0x03
    def decode_cmd(0x04), do: :pong

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

    def encode_cmd(Msg.WriteEvents), do: 0x82
    #def decode_cmd(0x82), do: Extreme.Messages.WriteEvents
    #def encode_cmd(Extreme.Messages.WriteEventsCompleted), do: 0x83
    def decode_cmd(0x83), do: Msg.WriteEventsCompleted

    def encode_cmd(:transaction_start), do: 0x84
    def encode_cmd(:transaction_start_completed), do: 0x85
    def encode_cmd(:transaction_write), do: 0x86
    def encode_cmd(:transaction_write_completed), do: 0x87
    def encode_cmd(:transaction_commit), do: 0x88
    def encode_cmd(:transaction_commit_completed), do: 0x89

    def encode_cmd(:delete_stream), do: 0x8A
    def encode_cmd(:delete_stream_completed), do: 0x8B

    def encode_cmd(Msg.ReadEvent), do: 0xB0
    def decode_cmd(0xB1), do: Msg.ReadEventCompleted
    # def encode_cmd(:read_stream_events_forward), do: 0xB2
    # def encode_cmd(:read_stream_events_forward_completed), do: 0xB3
    def encode_cmd(Msg.ReadStreamEvents), do: 0xB2
    def decode_cmd(0xB3), do: Msg.ReadStreamEventsCompleted

    def encode_cmd(:read_stream_events_backward), do: 0xB4
    def encode_cmd(:read_stream_events_backward_completed), do: 0xB5
    def encode_cmd(:read_all_events_forward), do: 0xB6
    def encode_cmd(:read_all_events_forward_completed), do: 0xB7
    def encode_cmd(:read_all_events_backward), do: 0xB8
    def encode_cmd(:read_all_events_backward_completed), do: 0xB9

    def encode_cmd(:subscribe_to_stream), do: 0xC0
    def encode_cmd(:subscription_confirmation), do: 0xC1
    def encode_cmd(:stream_event_appeared), do: 0xC2
    def encode_cmd(:unsubscribe_from_stream), do: 0xC3
    def encode_cmd(:subscription_dropped), do: 0xC4
    def encode_cmd(:connect_to_persistent_subscription), do: 0xC5
    def encode_cmd(:persistent_subscription_confirmation), do: 0xC6
    def encode_cmd(:persistent_subscription_stream_event_appeared), do: 0xC7
    def encode_cmd(:create_persistent_subscription), do: 0xC8
    def encode_cmd(:create_persistent_subscription_completed), do: 0xC9
    def encode_cmd(:delete_persistent_subscription), do: 0xCA
    def encode_cmd(:delete_persistent_subscription_completed), do: 0xCB
    def encode_cmd(:persistent_subscription_ack_events), do: 0xCC
    def encode_cmd(:persistent_subscription_nak_events), do: 0xCD
    def encode_cmd(:update_persistent_subscription), do: 0xCE
    def encode_cmd(:update_persistent_subscription_completed), do: 0xCF

    def encode_cmd(:scavenge_database), do: 0xD0
    def encode_cmd(:scavenge_database_completed), do: 0xD1

    def encode_cmd(:bad_request), do: 0xF0
    def encode_cmd(:not_handled), do: 0xF1
    def encode_cmd(:authenticate), do: 0xF2
    def encode_cmd(:authenticated), do: 0xF3

    def encode_cmd(:not_authenticated), do: 0xF4
    def decode_cmd(0xF4), do: :not_authenticated


end

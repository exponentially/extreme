defmodule Extreme.MessageResolver do
	# _Hartbeat command
	def encode_cmd(:heartbeat_request_command), do: 0x01
	def encode_cmd(:heartbeat_response_command), do: 0x02
	# _Ping command
	def encode_cmd(:ping), do: 0x03
	def encode_cmd(:pong), do: 0x04

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

    def encode_cmd(:write_events), do: 0x82
    def encode_cmd(:write_events_completed), do: 0x83

    def encode_cmd(:transaction_start), do: 0x84
    def encode_cmd(:transaction_start_completed), do: 0x85
    def encode_cmd(:transaction_write), do: 0x86
    def encode_cmd(:transaction_write_completed), do: 0x87
    def encode_cmd(:transaction_commit), do: 0x88
    def encode_cmd(:transaction_commit_completed), do: 0x89

    def encode_cmd(:delete_stream), do: 0x8A
    def encode_cmd(:delete_stream_completed), do: 0x8B

    def encode_cmd(:read_event), do: 0xB0
    def encode_cmd(:read_event_completed), do: 0xB1
    def encode_cmd(:read_stream_events_forward), do: 0xB2
    def encode_cmd(:read_stream_events_forward_completed), do: 0xB3
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

    # DECODE
	# _Hartbeat command
	def decode_cmd(0x01), do: :heartbeat_request_command
	def decode_cmd(0x02), do: :heartbeat_response_command
	# _Ping command
	def decode_cmd(0x03), do: :ping
	def decode_cmd(0x04), do: :pong

	# def decode_cmd(0x05), do: :prepare_ack
	# def decode_cmd(:0x06), do: :commit_ack

	# def decode_cmd(0x07), do: :slave_assignment
 	# def decode_cmd(:clone_assignment), do: 0x08

	# def decode_cmd(0x10), do: :subscribe_replica
	# def decode_cmd(0x11), do: :replica_log_position_ack
	# def decode_cmd(0x12), do: :create_chunk
	# def decode_cmd(0x13), do: :raw_chunk_bulk
	# def decode_cmd(0x14), do: :data_chunk_bulk
	# def decode_cmd(0x15), do: :replica_subscription_retry
	# def encode_cmd(0x16), do: :replica_subscribed
 
    # def decode_cmd(0x80), do: :create_stream
    # def decode_cmd(0x81), do: :create_stream_completed

    def decode_cmd(0x82), do: :write_events
    def decode_cmd(0x83), do: :write_events_completed

    def decode_cmd(0x84), do: :transaction_start
    def decode_cmd(0x85), do: :transaction_start_completed
    def decode_cmd(0x86), do: :transaction_write
    def decode_cmd(0x87), do: :transaction_write_completed
    def decode_cmd(0x88), do: :transaction_commit
    def decode_cmd(0x89), do: :transaction_commit_completed

    def decode_cmd(0x8A), do: :delete_stream
    def decode_cmd(0x8B), do: :delete_stream_completed

    def decode_cmd(0xB0), do: :read_event
    def decode_cmd(0xB1), do: :read_event_completed
    def decode_cmd(0xB2), do: :read_stream_events_forward
    def decode_cmd(0xB3), do: :read_stream_events_forward_completed
    def decode_cmd(0xB4), do: :read_stream_events_backward
    def decode_cmd(0xB5), do: :read_stream_events_backward_completed
    def decode_cmd(0xB6), do: :read_all_events_forward
    def decode_cmd(0xB7), do: :read_all_events_forward_completed
    def decode_cmd(0xB8), do: :read_all_events_backward
    def decode_cmd(0xB9), do: :read_all_events_backward_completed

    def decode_cmd(0xC0), do: :subscribe_to_stream
    def decode_cmd(0xC1), do: :subscription_confirmation
    def decode_cmd(0xC2), do: :stream_event_appeared
    def decode_cmd(0xC3), do: :unsubscribe_from_stream
    def decode_cmd(0xC4), do: :subscription_dropped
    def decode_cmd(0xC5), do: :connect_to_persistent_subscription
    def decode_cmd(0xC6), do: :persistent_subscription_confirmation
    def decode_cmd(0xC7), do: :persistent_subscription_stream_event_appeared
    def decode_cmd(0xC8), do: :create_persistent_subscription
    def decode_cmd(0xC9), do: :create_persistent_subscription_completed
    def decode_cmd(0xCA), do: :delete_persistent_subscription
    def decode_cmd(0xCB), do: :delete_persistent_subscription_completed
    def decode_cmd(0xCC), do: :persistent_subscription_ack_events
    def decode_cmd(0xCD), do: :persistent_subscription_nak_events
    def decode_cmd(0xCE), do: :update_persistent_subscription
    def decode_cmd(0xCF), do: :update_persistent_subscription_completed

    def decode_cmd(0xD0), do: :scavenge_database
    def decode_cmd(0xD1), do: :scavenge_database_completed

    def decode_cmd(0xF0), do: :bad_request
    def decode_cmd(0xF1), do: :not_handled
    def decode_cmd(0xF2), do: :authenticate
    def decode_cmd(0xF3), do: :authenticated
    def decode_cmd(0xF4), do: :not_authenticated


end
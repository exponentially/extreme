defmodule Extreme.MessageResolver do
	# _Hartbeat command
	def encode_cmd(:heartbeat_request_command) do: 0x01 end
	def encode_cmd(:heartbeat_response_command) do: 0x02 end
	# _Ping command
	def encode_cmd(:ping) do: 0x03 end
	def encode_cmd(:pong) do: 0x04 end

	# def encode_cmd(:prepare_ack) do: 0x05 end
	# def encode_cmd(:commit_ack) do: 0x06 end

	# def encode_cmd(:slave_assignment) do: 0x07 end
 	# def encode_cmd(0x08) do: :clone_assignment end

	# def encode_cmd(:subscribe_replica) do: 0x10 end
	# def encode_cmd(:replica_log_position_ack) do: 0x11 end
	# def encode_cmd(:create_chunk) do: 0x12 end
	# def encode_cmd(:raw_chunk_bulk) do: 0x13 end
	# def encode_cmd(:data_chunk_bulk) do: 0x14 end
	# def encode_cmd(:replica_subscription_retry) do: 0x15 end
	# def encode_cmd(:replica_subscribed) do: 0x16 end
 
    # def encode_cmd(:create_stream) do: 0x80 end
    # def encode_cmd(:create_stream_completed) do: 0x81 end

    def encode_cmd(:write_events) do: 0x82 end
    def encode_cmd(:write_events_completed) do: 0x83 end

    def encode_cmd(:transaction_start) do: 0x84 end
    def encode_cmd(:transaction_start_completed) do: 0x85 end
    def encode_cmd(:transaction_write) do: 0x86 end
    def encode_cmd(:transaction_write_completed) do: 0x87 end
    def encode_cmd(:transaction_commit) do: 0x88 end
    def encode_cmd(:transaction_commit_completed) do: 0x89 end

    def encode_cmd(:delete_stream) do: 0x8A end
    def encode_cmd(:delete_stream_completed) do: 0x8B end

    def encode_cmd(:read_event) do: 0xB0 end
    def encode_cmd(:read_event_completed) do: 0xB1 end
    def encode_cmd(:read_stream_events_forward) do: 0xB2 end
    def encode_cmd(:read_stream_events_forward_completed) do: 0xB3 end
    def encode_cmd(:read_stream_events_backward) do: 0xB4 end
    def encode_cmd(:read_stream_events_backward_completed) do: 0xB5 end
    def encode_cmd(:read_all_events_forward) do: 0xB6 end
    def encode_cmd(:read_all_events_forward_completed) do: 0xB7 end
    def encode_cmd(:read_all_events_backward) do: 0xB8 end
    def encode_cmd(:read_all_events_backward_completed) do: 0xB9 end

    def encode_cmd(:subscribe_to_stream) do: 0xC0 end
    def encode_cmd(:subscription_confirmation) do: 0xC1 end
    def encode_cmd(:stream_event_appeared) do: 0xC2 end
    def encode_cmd(:unsubscribe_from_stream) do: 0xC3 end
    def encode_cmd(:subscription_dropped) do: 0xC4 end
    def encode_cmd(:connect_to_persistent_subscription) do: 0xC5 end
    def encode_cmd(:persistent_subscription_confirmation) do: 0xC6 end
    def encode_cmd(:persistent_subscription_stream_event_appeared) do: 0xC7 end
    def encode_cmd(:create_persistent_subscription) do: 0xC8 end
    def encode_cmd(:create_persistent_subscription_completed) do: 0xC9 end
    def encode_cmd(:delete_persistent_subscription) do: 0xCA end
    def encode_cmd(:delete_persistent_subscription_completed) do: 0xCB end
    def encode_cmd(:persistent_subscription_ack_events) do: 0xCC end
    def encode_cmd(:persistent_subscription_nak_events) do: 0xCD end
    def encode_cmd(:update_persistent_subscription) do: 0xCE end
    def encode_cmd(:update_persistent_subscription_completed) do: 0xCF end

    def encode_cmd(:scavenge_database) do: 0xD0 end
    def encode_cmd(:scavenge_database_completed) do: 0xD1 end

    def encode_cmd(:bad_request) do: 0xF0 end
    def encode_cmd(:not_handled) do: 0xF1 end
    def encode_cmd(:authenticate) do: 0xF2 end
    def encode_cmd(:authenticated) do: 0xF3 end
    def encode_cmd(:not_authenticated) do: 0xF4 end

    # DECODE
	# _Hartbeat command
	def decode_cmd(0x01) do: :heartbeat_request_command end
	def decode_cmd(0x02) do: :heartbeat_response_command end
	# _Ping command
	def decode_cmd(0x03) do: :ping end
	def decode_cmd(0x04) do: :pong end

	# def decode_cmd(0x05) do: :prepare_ack end
	# def decode_cmd(:0x06) do: :commit_ack end

	# def decode_cmd(0x07) do: :slave_assignment end
 	# def decode_cmd(:clone_assignment) do: 0x08 end

	# def decode_cmd(0x10) do: :subscribe_replica end
	# def decode_cmd(0x11) do: :replica_log_position_ack end
	# def decode_cmd(0x12) do: :create_chunk end
	# def decode_cmd(0x13) do: :raw_chunk_bulk end
	# def decode_cmd(0x14) do: :data_chunk_bulk end
	# def decode_cmd(0x15) do: :replica_subscription_retry end
	# def encode_cmd(0x16) do: :replica_subscribed end
 
    # def decode_cmd(0x80) do: :create_stream end
    # def decode_cmd(0x81) do: :create_stream_completed end

    def decode_cmd(0x82) do: :write_events end
    def decode_cmd(0x83) do: :write_events_completed end

    def decode_cmd(0x84) do: :transaction_start end
    def decode_cmd(0x85) do: :transaction_start_completed end
    def decode_cmd(0x86) do: :transaction_write end
    def decode_cmd(0x87) do: :transaction_write_completed end
    def decode_cmd(0x88) do: :transaction_commit end
    def decode_cmd(0x89) do: :transaction_commit_completed end

    def decode_cmd(0x8A) do: :delete_stream end
    def decode_cmd(0x8B) do: :delete_stream_completed end

    def decode_cmd(0xB0) do: :read_event end
    def decode_cmd(0xB1) do: :read_event_completed end
    def decode_cmd(0xB2) do: :read_stream_events_forward end
    def decode_cmd(0xB3) do: :read_stream_events_forward_completed end
    def decode_cmd(0xB4) do: :read_stream_events_backward end
    def decode_cmd(0xB5) do: :read_stream_events_backward_completed end
    def decode_cmd(0xB6) do: :read_all_events_forward end
    def decode_cmd(0xB7) do: :read_all_events_forward_completed end
    def decode_cmd(0xB8) do: :read_all_events_backward end
    def decode_cmd(0xB9) do: :read_all_events_backward_completed end

    def decode_cmd(0xC0) do: :subscribe_to_stream end
    def decode_cmd(0xC1) do: :subscription_confirmation end
    def decode_cmd(0xC2) do: :stream_event_appeared end
    def decode_cmd(0xC3) do: :unsubscribe_from_stream end
    def decode_cmd(0xC4) do: :subscription_dropped end
    def decode_cmd(0xC5) do: :connect_to_persistent_subscription end
    def decode_cmd(0xC6) do: :persistent_subscription_confirmation end
    def decode_cmd(0xC7) do: :persistent_subscription_stream_event_appeared end
    def decode_cmd(0xC8) do: :create_persistent_subscription end
    def decode_cmd(0xC9) do: :create_persistent_subscription_completed end
    def decode_cmd(0xCA) do: :delete_persistent_subscription end
    def decode_cmd(0xCB) do: :delete_persistent_subscription_completed end
    def decode_cmd(0xCC) do: :persistent_subscription_ack_events end
    def decode_cmd(0xCD) do: :persistent_subscription_nak_events end
    def decode_cmd(0xCE) do: :update_persistent_subscription end
    def decode_cmd(0xCF) do: :update_persistent_subscription_completed end

    def decode_cmd(0xD0) do: :scavenge_database end
    def decode_cmd(0xD1) do: :scavenge_database_completed end

    def decode_cmd(0xF0) do: :bad_request end
    def decode_cmd(0xF1) do: :not_handled end
    def decode_cmd(0xF2) do: :authenticate end
    def decode_cmd(0xF3) do: :authenticated end
    def decode_cmd(0xF4) do: :not_authenticated end


end
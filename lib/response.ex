defmodule Extreme.Response do
	alias Extreme.Messages, as: Msg
	require Logger

	def reply(%Msg.DeleteStreamCompleted{}=data, _auth) do
		{data.result, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.TransactionWriteCompleted{}=data, _auth) do
		{data.result, data.transaction_id}
	end

	def reply(%Msg.TransactionStartCompleted{}=data, _auth) do
		{data.result, data.transaction_id}
	end

	def reply(%Msg.TransactionCommitCompleted{}=data, _auth) do
		{data.result, data.transaction_id, data.first_event_number, data.last_event_number, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.WriteEventsCompleted{}=data, _auth) do
		{data.result, data.first_event_number, data.last_event_number}
	end

	def reply(%Msg.ReadStreamEventsCompleted{}=data, _auth) do
		events = Enum.map(data.events, fn e -> 
			event_type = String.to_atom(e.event.event_type)
			Poison.decode!(e.event.data, as: event_type)
		end)
		last_event_number = data.last_event_number
		{data.result, events, last_event_number}
	end

	def reply(%Msg.ReadEventCompleted{}=data, _auth) do 
		#IO.puts inspect data
		event_type = String.to_atom(data.event.event.event_type)
		event = Poison.decode!(data.event.event.data, as: event_type)
		{data.result, event}
	end

	def reply(1, _auth) do
		Logger.debug "HEARTBEAT"
	end

	def reply(response, _auth) do
		Logger.error "Unhandled response: #{inspect response}"
		{:unhandled_response_type, response.__struct__}
	end

end
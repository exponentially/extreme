defmodule Extreme.Response do
	alias Extreme.Messages, as: Msg
	require Logger

	def reply(%Msg.DeleteStreamCompleted{result: :Success}=data) do
		{:success, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.TransactionWriteCompleted{result: :Success}=data) do
		{:success, data.transaction_id}
	end

	def reply(%Msg.TransactionStartCompleted{result: :Success}=data) do
		{:success, data.transaction_id}
	end

	def reply(%Msg.TransactionCommitCompleted{result: :Success}=data) do
		{:success, data.transaction_id, data.first_event_number, data.last_event_number, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.WriteEventsCompleted{result: :Success}=data) do
		{:success, data.first_event_number, data.last_event_number}
	end

	def reply(%Msg.ReadStreamEventsCompleted{result: :Success}=data) do
		events = Enum.map(data.events, fn e -> 
			event_type = String.to_atom(e.event.event_type)
			Poison.decode!(e.event.data, as: event_type)
		end)
		last_event_number = data.last_event_number
		{:success, events, last_event_number}
	end

	def reply(%{result: :NoStream}), do: {:error, :no_stream}
	def reply(%{result: :NotFound}), do: {:error, :not_found}
	def reply(%{result: :StreamDeleted}), do: {:error, :stream_deleted}

	def reply(%Msg.ReadEventCompleted{event: indexed_event, result: :Success}=data) do 
		# todo: linked events!!!
		event_type = String.to_atom(indexed_event.event.event_type)
		event = Poison.decode!(indexed_event.event.data, as: event_type)
		{:success, event}
	end

	def reply(1) do
		Logger.debug "HEARTBEAT"
	end

	def reply(response) do
		Logger.error "Unhandled response: #{inspect response}"
		{:unhandled_response_type, response.__struct__}
	end

end
defmodule Extreme.Response do
	alias Extreme.Messages, as: Msg
	require Logger

	def reply(%Msg.DeleteStreamCompleted{result: :Success}=data) do
		{:ok, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.TransactionWriteCompleted{result: :Success}=data) do
		{:ok, data.transaction_id}
	end

	def reply(%Msg.TransactionStartCompleted{result: :Success}=data) do
		{:ok, data.transaction_id}
	end

	def reply(%Msg.TransactionCommitCompleted{result: :Success}=data) do
		{:ok, data.transaction_id, data.first_event_number, data.last_event_number, data.prepare_position, data.commit_position}
	end

	def reply(%Msg.WriteEventsCompleted{result: :Success}=data) do
		{:ok, data.first_event_number, data.last_event_number}
	end

	def reply(%Msg.ReadStreamEventsCompleted{result: :Success}=data) do
		events = Enum.map(data.events, fn e -> 
			event_type = e.event.event_type
            {event_type, e.event.data}
		end)
		{:ok, events, data.last_event_number, data.is_end_of_stream}
	end

	def reply(%{result: :NoStream}), do: {:error, :no_stream}
	def reply(%{result: :NotFound}), do: {:error, :not_found}
	def reply(%{result: :StreamDeleted}), do: {:error, :stream_deleted}

	def reply(%Msg.ReadEventCompleted{event: indexed_event, result: :Success}) do 
		# todo: linked events!!!
		event_type = String.to_atom(indexed_event.event.event_type)
		{:ok, event_type, indexed_event.event.data}
	end

	def reply(1) do
		Logger.debug "HEARTBEAT"
	end

	def reply(response) do
		Logger.error "Unhandled response: #{inspect response}"
		{:unhandled_response_type, response.__struct__}
	end

end

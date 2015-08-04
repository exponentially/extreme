defmodule Extreme.Response do
	require Logger

	def reply(%{result: :Success} = data), do: {:ok, data}
	def reply(%{result: _} = data), do: {:error, data.result, data}
	def reply({:error, reason}), do: {:error, reason}
	def reply(1), do: Logger.debug "HEARTBEAT"
	def reply(response) do
		Logger.error "Unhandled response: #{inspect response}"
		{:error, :unhandled_response_type, response}
	end
end

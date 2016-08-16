defmodule Extreme.Response do
  require Logger
  alias Extreme.Messages, as: ExMsg

  def parse(<<message_type,
              auth,
              correlation_id :: 16-binary,
              data :: binary>>) do
    case Extreme.MessageResolver.decode_cmd(message_type) do
      :not_authenticated         -> {:error, :not_authenticated, correlation_id}
      :heartbeat_request_command -> {:heartbeat_request, correlation_id}
      :pong                      -> {:pong, correlation_id}
      response_struct            ->
        data = response_struct.decode data
        {auth, correlation_id, data}
    end
  end

  def reply(%{result: :Success} = data),               do: {:ok, data}
  def reply(%ExMsg.SubscriptionConfirmation{} = data), do: {:ok, data}
  #def reply(%ExMsg.SubscriptionDropped{} = data),     do: {:ok, data}
  def reply(%ExMsg.StreamEventAppeared{} = data),      do: {:ok, data}
  def reply(%{result: _} = data),                      do: {:error, data.result, data}
  def reply({:error, reason}),                         do: {:error, reason}
  def reply(1),                                        do: Logger.debug "HEARTBEAT"
  def reply(response) do
    Logger.error "Unhandled response: #{inspect response}"
    {:error, :unhandled_response_type, response}
  end
end

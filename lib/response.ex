defmodule Extreme.Response do
  require Logger
  alias Extreme.Msg, as: ExMsg

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

  def reply(%{result: :Success} = data, _correlation_id),               do: {:ok, data}
  def reply(%ExMsg.SubscriptionConfirmation{} = data, _correlation_id), do: {:ok, data}
  def reply(%ExMsg.PersistentSubscriptionConfirmation{} = data, _correlation_id), do: {:ok, data}
  def reply(%ExMsg.SubscriptionDropped{} = data, _correlation_id),     do: {:ok, data}
  def reply(%ExMsg.StreamEventAppeared{} = data, _correlation_id),      do: {:ok, data}
  def reply(%ExMsg.PersistentSubscriptionStreamEventAppeared{} = data, correlation_id), do: {:ok, data, correlation_id}
  def reply(%{result: _} = data, _correlation_id),                      do: {:error, data.result, data}
  def reply({:error, reason}, _correlation_id),                         do: {:error, reason}
  def reply(1, _correlation_id),                                        do: Logger.debug "HEARTBEAT"
  def reply(response, _correlation_id) do
    Logger.error "Unhandled response: #{inspect response}"
    {:error, :unhandled_response_type, response}
  end
end

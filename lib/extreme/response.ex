defmodule Extreme.Response do
  require Logger
  alias Extreme.Messages, as: Msg

  def get_correlation_id(<<_message_type, _auth, correlation_id::16-binary, _data::binary>>),
    do: correlation_id

  def parse(<<message_type, auth, correlation_id::16-binary, data::binary>>) do
    case Extreme.MessageResolver.decode_cmd(message_type) do
      :not_authenticated ->
        {:error, :not_authenticated, correlation_id}

      :heartbeat_request_command ->
        {:heartbeat_request, correlation_id}

      :pong ->
        {:pong, correlation_id}

      :client_identified ->
        {:client_identified, correlation_id}

      :bad_request ->
        {:error, :bad_request, correlation_id}

      response_struct ->
        data = response_struct.decode(data)
        {auth, correlation_id, data}
    end
  end

  # def reply(%{result: :Success} = data, _correlation_id), do: {:ok, data}
  # def reply(%Msg.SubscriptionConfirmation{} = data, _correlation_id), do: {:ok, data}
  # def reply(%Msg.PersistentSubscriptionConfirmation{} = data, _correlation_id), do: {:ok, data}
  # def reply(%Msg.SubscriptionDropped{} = data, _correlation_id), do: {:ok, data}
  # def reply(%Msg.StreamEventAppeared{} = data, _correlation_id), do: {:ok, data}

  # def reply(%Msg.PersistentSubscriptionStreamEventAppeared{} = data, correlation_id),
  #  do: {:ok, data, correlation_id}

  # def reply(%{result: _} = data, _correlation_id), do: {:error, data.result, data}
  # def reply(1, _correlation_id), do: Logger.debug("HEARTBEAT")
  # def reply({:error, reason}, _correlation_id), do: {:error, reason}
  def reply(
        %Msg.WriteEventsCompleted{message: "Stream is deleted.", current_version: -1},
        _correlation_id
      ),
      do: {:error, :stream_deleted}

  def reply(
        %Msg.ReadStreamEventsCompleted{
          is_end_of_stream: true,
          last_event_number: -1,
          next_event_number: -1
        },
        _correlation_id
      ),
      do: {:warn, :empty_stream}

  def reply(
        %Msg.ReadStreamEventsCompleted{
          events: [],
          is_end_of_stream: true,
          last_event_number: last_event_number,
          next_event_number: -1
        },
        _correlation_id
      )
      when last_event_number > -1,
      do: {:error, :stream_deleted}

  def reply(
        %Extreme.Messages.ReadEventCompleted{
          error: nil,
          event: %Extreme.Messages.ResolvedIndexedEvent{
            event: nil,
            link: nil
          }
        },
        _correlation_id
      ),
      do: {:error, :not_found}

  def reply(response, _correlation_id), do: {:ok, response}

  # def reply(response, _correlation_id) do
  #  Logger.error("Unhandled response: #{inspect(response)}")
  #  {:error, :unhandled_response_type, response}
  # end
end

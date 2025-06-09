defmodule Extreme.Reading do
  alias Extreme.RequestManager
  alias Extreme.Messages, as: ExMsg

  require Logger

  @dont_reduce :dont_reduce

  defmodule Params do
    @type t() :: %__MODULE__{
            stream: String.t(),
            direction: :forward | :backwards,
            from_event_number: integer(),
            read_until: :all | integer(),
            per_page: integer(),
            resolve_link_tos: boolean(),
            require_master: boolean()
          }

    defstruct ~w(stream direction from_event_number read_until per_page resolve_link_tos require_master )a

    @spec new(map()) :: t()
    def new(%{} = opts) do
      %__MODULE__{
        direction: :forward,
        from_event_number: 0,
        read_until: :all,
        per_page: 100,
        resolve_link_tos: true,
        require_master: false
      }
      |> Map.merge(opts)
    end

    @spec new_backwards(map()) :: t()
    def new_backwards(%{} = opts) do
      %__MODULE__{
        direction: :backwards,
        from_event_number: -1,
        read_until: :all,
        per_page: 100,
        resolve_link_tos: true,
        require_master: false
      }
      |> Map.merge(opts)
    end
  end

  @spec read_events(module(), Params.t(), (ExMsg.StreamEventAppeared.t() ->
                                             :ok | :stop | {:stop, response :: any()})) ::
          :finished
          | {:stopped, response :: any()}
          | {:error, :no_stream | :stream_hard_deleted}
          | {:error, :unexpected_processing_response, any()}
  def read_events(base_name, %Params{} = params, fun) do
    base_name
    |> reduce_events(@dont_reduce, params, fun)
    |> case do
      {:finished, _} -> :finished
      other -> other
    end
  end

  @spec reduce_events(module(), any(), Params.t(), (ExMsg.StreamEventAppeared.t(), acc :: any() ->
                                                      {:ok, acc :: any}
                                                      | {:stop, acc :: any()})) ::
          {:finished, acc :: any()}
          | {:stopped, acc :: any()}
          | {:error, :no_stream | :stream_hard_deleted}
          | {:error, :unexpected_processing_response, any()}
  def reduce_events(base_name, acc, %Params{} = params, fun) do
    params
    |> _build_request()
    |> case do
      {request, false} ->
        base_name
        |> _execute_read(request, params, fun, acc)
        |> case do
          {:end_of_stream, acc} -> {:finished, acc}
          {:continue, _, acc} -> {:finished, acc}
          other -> other
        end

      {request, true} ->
        base_name
        |> _execute_read(request, params, fun, acc)
        |> case do
          {:end_of_stream, acc} ->
            {:finished, acc}

          {:continue, from, acc} ->
            reduce_events(base_name, acc, %Params{params | from_event_number: from}, fun)

          other ->
            other
        end
    end
  end

  defp _execute_read(base_name, request, params, fun, acc) do
    base_name
    |> RequestManager.execute(request, Extreme.Tools.generate_uuid())
    |> _process_read_response(params, fun, acc)
  end

  @spec _build_request(Params.t()) :: {ExMsg.ReadStreamEvents.t(), continue? :: boolean()}
  defp _build_request(
         %Params{
           direction: :forward,
           read_until: :all
         } = params
       ) do
    request =
      ExMsg.ReadStreamEvents.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, true}
  end

  defp _build_request(
         %Params{
           direction: :forward,
           from_event_number: from,
           per_page: per_page,
           read_until: read_until
         } = params
       )
       when is_integer(read_until) and from + per_page < read_until do
    request =
      ExMsg.ReadStreamEvents.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, true}
  end

  defp _build_request(%Params{direction: :forward} = params) do
    request =
      ExMsg.ReadStreamEvents.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.read_until - params.from_event_number,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, false}
  end

  # backwards

  defp _build_request(
         %Params{
           direction: :backwards,
           from_event_number: -1
         } = params
       ) do
    request =
      ExMsg.ReadStreamEventsBackward.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, true}
  end

  defp _build_request(
         %Params{
           direction: :backwards,
           read_until: :all
         } = params
       ) do
    request =
      ExMsg.ReadStreamEventsBackward.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, true}
  end

  defp _build_request(
         %Params{
           direction: :backwards,
           from_event_number: from,
           per_page: per_page,
           read_until: read_until
         } = params
       )
       when from - per_page > read_until do
    request =
      ExMsg.ReadStreamEventsBackward.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.per_page,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, true}
  end

  defp _build_request(%Params{direction: :backwards} = params) do
    request =
      ExMsg.ReadStreamEventsBackward.new(
        event_stream_id: params.stream,
        from_event_number: params.from_event_number,
        max_count: params.from_event_number - params.read_until,
        resolve_link_tos: params.resolve_link_tos,
        require_master: params.require_master
      )

    {request, false}
  end

  defp _process_read_response({:error, :stream_deleted, _}, _params, _fun, _acc),
    do: {:error, :stream_hard_deleted}

  defp _process_read_response({:error, :no_stream, _}, _params, _fun, _acc),
    do: {:error, :no_stream}

  defp _process_read_response(
         {:ok, %ExMsg.ReadStreamEventsCompleted{} = response},
         %Params{} = params,
         fun,
         acc
       ) do
    Logger.debug(fn ->
      last_read_event_number =
        case params do
          %Params{direction: :forward} -> response.next_event_number - 1
          %Params{direction: :backwards} -> response.next_event_number + 1
        end

      "Last read event: #{last_read_event_number}"
    end)

    response.events
    |> Enum.reduce_while({:continue, response.next_event_number, acc}, fn
      msg, {:continue, _, acc} ->
        msg
        |> _process_message(params, fun, acc)
        |> case do
          {:out_of_requested_bounds, acc} ->
            {:halt, {:continue, response.next_event_number, acc}}

          {:ok, acc} ->
            {:cont, {:continue, response.next_event_number, acc}}

          {:stop, @dont_reduce} ->
            Logger.info("Processing of read message is stopped")
            {:halt, {:stopped, nil}}

          {{:stop, return}, @dont_reduce} ->
            Logger.info("Processing of read message is stopped")
            {:halt, {:stopped, return}}

          {:stop, return} ->
            Logger.info("Processing of read message is stopped")
            {:halt, {:stopped, return}}

          {other, @dont_reduce} ->
            Logger.warning(
              "Processing of read message didn't succeed [msg, response]: #{inspect([msg, other])}"
            )

            {:halt, {:error, :unexpected_processing_response, other}}

          other ->
            Logger.warning(
              "Processing of read message didn't succeed [msg, response]: #{inspect([msg, other])}"
            )

            {:halt, {:error, :unexpected_processing_response, other}}
        end
    end)
    |> case do
      {:continue, _, acc} = resp ->
        if response.is_end_of_stream,
          do: {:end_of_stream, acc},
          else: resp

      other ->
        other
    end
  end

  defp _process_message(
         msg,
         %Params{direction: :backwards, from_event_number: -1, read_until: read_until},
         fun,
         acc
       )
       when is_integer(read_until) do
    if _event_number(msg) <= read_until do
      {:out_of_requested_bounds, acc}
    else
      if acc == @dont_reduce do
        {fun.(msg), acc}
      else
        fun.(msg, acc)
      end
    end
  end

  defp _process_message(msg, _, fun, @dont_reduce),
    do: {fun.(msg), @dont_reduce}

  defp _process_message(msg, _, fun, acc),
    do: fun.(msg, acc)

  defp _event_number(%{event: event, link: nil}),
    do: event.event_number

  defp _event_number(%{link: link}),
    do: link.event_number
end

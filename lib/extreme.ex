defmodule Extreme do
  @moduledoc """
  TODO
  """

  @type t :: module

  @typedoc "An event as read from a stream and passed to `read_events` and `reduce_events` functions."
  @type read_event :: Extreme.Messages.ResolvedIndexedEvent.t()

  @doc false
  defmacro __using__(opts \\ []) do
    quote do
      alias Extreme.Messages, as: ExMsg

      @otp_app Keyword.get(unquote(opts), :otp_app, :extreme)

      defp _default_config,
        do: Application.get_env(@otp_app, __MODULE__)

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(config \\ [])
      def start_link([]), do: Extreme.Supervisor.start_link(__MODULE__, _default_config())
      def start_link(config), do: Extreme.Supervisor.start_link(__MODULE__, config)

      def ping,
        do: Extreme.RequestManager.ping(__MODULE__, Extreme.Tools.generate_uuid())

      def execute(message, correlation_id \\ nil, timeout \\ 5_000) do
        Extreme.RequestManager.execute(
          __MODULE__,
          message,
          correlation_id || Extreme.Tools.generate_uuid(),
          timeout
        )
      end

      @doc """
      Reads events from `stream_name` given `opts` 
      as keyword list of `Extreme.Reading.Params` keys,
      and invokes `fun` for each read event. `fun` should return `:ok` or `:stop`
      if further processing of events should be stopped
      """
      @spec read_events(String.t(), Keyword.t(), (Extreme.read_event() ->
                                                    :ok
                                                    | :stop
                                                    | {:stop, response :: any()})) ::
              :finished
              | {:stopped, response :: nil | any()}
              | {:error, :no_stream | :stream_hard_deleted}
              | {:error, :unexpected_processing_response, any()}
      def read_events(stream_name, opts \\ [], fun) do
        params =
          [{:stream, stream_name} | opts]
          |> Enum.into(%{})
          |> Extreme.Reading.Params.new()

        Extreme.Reading.read_events(__MODULE__, params, fun)
      end

      @doc """
      Reads events backwards from `stream_name` given `opts`
      as keyword list of `Extreme.Reading.Params` keys,
      and invokes `fun` for each read event. `fun` should return `:ok` or `:stop`
      if further processing of events should be stopped
      """
      @spec read_events_backwards(String.t(), Keyword.t(), (Extreme.read_event() ->
                                                              :ok
                                                              | :stop
                                                              | {:stop, response :: any()})) ::
              :finished
              | {:stopped, response :: any()}
              | {:error, :no_stream | :stream_hard_deleted}
              | {:error, :unexpected_processing_response, any()}
      def read_events_backwards(stream_name, opts \\ [], fun) do
        params =
          [{:stream, stream_name} | opts]
          |> Enum.into(%{})
          |> Extreme.Reading.Params.new_backwards()

        Extreme.Reading.read_events(__MODULE__, params, fun)
      end

      @spec reduce_events(acc :: any(), String.t(), Keyword.t(), (Extreme.read_event(),
                                                                  acc :: any() ->
                                                                    {:ok, acc :: any()}
                                                                    | {:stop, acc :: any()})) ::
              {:finished, acc :: any()}
              | {:stopped, acc :: any()}
              | {:error, :no_stream | :stream_hard_deleted}
              | {:error, :unexpected_processing_response, any()}
      def reduce_events(acc, stream_name, opts \\ [], fun) do
        params =
          [{:stream, stream_name} | opts]
          |> Enum.into(%{})
          |> Extreme.Reading.Params.new()

        Extreme.Reading.reduce_events(__MODULE__, acc, params, fun)
      end

      @spec reduce_events_backwards(
              acc :: any(),
              String.t(),
              Keyword.t(),
              (Extreme.read_event(), acc :: any() ->
                 {:ok, acc :: any()}
                 | {:stop, acc :: any()})
            ) ::
              {:finished, acc :: any()}
              | {:stopped, acc :: any()}
              | {:error, :no_stream | :stream_hard_deleted}
              | {:error, :unexpected_processing_response, any()}
      def reduce_events_backwards(acc, stream_name, opts \\ [], fun) do
        params =
          [{:stream, stream_name} | opts]
          |> Enum.into(%{})
          |> Extreme.Reading.Params.new_backwards()

        Extreme.Reading.reduce_events(__MODULE__, acc, params, fun)
      end

      @doc """
      Sets metadata map to stream. To remove metadata, set an empty map.

      Example:

      ```elixir
      metadata = %{"$maxAge" => max_age_seconds}
      :ok = MyConn.set_metadata("user-123", metadata)
      ```
      """
      @spec set_metadata(String.t(), map()) :: :ok | any()
      def set_metadata(stream, %{} = metadata) do
        stream
        |> _write_metadata(metadata)
        |> execute()
        |> case do
          {:ok, %ExMsg.WriteEventsCompleted{result: :success}} -> :ok
          {:ok, %ExMsg.WriteEventsCompleted{result: result}} -> {:error, result}
          other -> other
        end
      end

      @doc """
      Gets metadata map from stream.

      Example:

      ```elixir
      stream = "users-123"
      MyConn.get_metadata(stream)
      #=> {:error, :no_stream}

      # keep events 1 day
      max_age_seconds = 60 * 60 * 24
      metadata = %{"$maxAge" => max_age_seconds}
      :ok = MyConn.set_metadata(stream, metadata)

      MyConn.get_metadata(stream)
      #=> {:ok, %{"$maxAge" => 86_400}}
      ```
      """
      @spec get_metadata(String.t()) :: {:ok, map()} | {:error, :no_stream}
      def get_metadata(stream) do
        stream
        |> _read_metadata()
        |> execute()
        |> case do
          {:error, :no_stream, %ExMsg.ReadStreamEventsCompleted{result: :no_stream}} ->
            {:error, :no_stream}

          {:ok,
           %ExMsg.ReadStreamEventsCompleted{
             events: [
               %ExMsg.ResolvedIndexedEvent{
                 event: %Extreme.Messages.EventRecord{
                   event_stream_id: "$$" <> ^stream,
                   event_type: "$metadata",
                   data: data
                 }
               }
               | _
             ],
             result: :success
           }} ->
            data
            |> Jason.decode()
            |> case do
              {:ok, decoded} -> {:ok, decoded}
              _ -> data
            end
        end
      end

      @doc """
      Starts database scavenge on current connection. Pay attention that
      if cluster is used, scavenge will be executed only on connected node!
      """
      @spec scavenge_database() :: :ok | any()
      def scavenge_database() do
        ExMsg.ScavengeDatabase.new()
        |> execute()
        |> case do
          {:ok, %Extreme.Messages.ScavengeDatabaseCompleted{result: :success}} -> :ok
          {:ok, %Extreme.Messages.ScavengeDatabaseCompleted{result: other}} -> {:error, other}
          other -> other
        end
      end

      defp _write_metadata(stream, %{} = metadata) do
        metadata_stream_name = "$$" <> stream

        proto_event =
          ExMsg.NewEvent.new(
            event_id: Extreme.Tools.generate_uuid(),
            event_type: "$metadata",
            data_content_type: 1,
            metadata_content_type: 1,
            data: Jason.encode!(metadata),
            metadata: ""
          )

        ExMsg.WriteEvents.new(
          event_stream_id: metadata_stream_name,
          expected_version: -2,
          events: [proto_event],
          require_master: false
        )
      end

      defp _read_metadata(stream) do
        metadata_stream_name = "$$" <> stream

        Extreme.Messages.ReadStreamEventsBackward.new(
          event_stream_id: metadata_stream_name,
          from_event_number: -1,
          max_count: 1,
          resolve_link_tos: false,
          require_master: false
        )
      end

      def subscribe_to(stream, subscriber, resolve_link_tos \\ true, ack_timeout \\ 5_000)
          when is_binary(stream) and is_pid(subscriber) and is_boolean(resolve_link_tos) do
        Extreme.RequestManager.subscribe_to(
          __MODULE__,
          stream,
          subscriber,
          resolve_link_tos,
          ack_timeout
        )
      end

      def read_and_stay_subscribed(
            stream,
            subscriber,
            from_event_number \\ 0,
            per_page \\ 1_000,
            resolve_link_tos \\ true,
            require_master \\ false,
            ack_timeout \\ 5_000
          )
          when is_binary(stream) and is_pid(subscriber) and is_boolean(resolve_link_tos) and
                 is_boolean(require_master) and from_event_number >= 0 and per_page > 0 and
                 per_page <= 4096 do
        Extreme.RequestManager.read_and_stay_subscribed(
          __MODULE__,
          subscriber,
          {stream, from_event_number, per_page, resolve_link_tos, require_master, ack_timeout}
        )
      end

      @spec start_event_producer(stream :: String.t(), subscriber :: pid(), opts :: Keyword.t()) ::
              Supervisor.on_start_child()
      def start_event_producer(stream, subscriber, opts \\ []) do
        Extreme.EventProducer.Supervisor.start_event_producer(
          __MODULE__,
          [{:stream, stream}, {:subscriber, subscriber} | opts]
        )
      end

      @spec subscribe_producer(producer :: pid()) :: :ok
      def subscribe_producer(producer),
        do: Extreme.EventProducer.subscribe(producer)

      @spec unsubscribe_producer(producer :: pid()) :: :ok
      def unsubscribe_producer(producer),
        do: Extreme.EventProducer.unsubscribe(producer)

      @spec producer_subscription_status(producer :: pid()) ::
              :disconnected | :catching_up | :live | :paused
      def producer_subscription_status(producer),
        do: Extreme.EventProducer.subscription_status(producer)

      def unsubscribe(subscription) when is_pid(subscription),
        do: Extreme.Subscription.unsubscribe(subscription)

      def connect_to_persistent_subscription(
            subscriber,
            stream,
            group,
            allowed_in_flight_messages
          ) do
        Extreme.RequestManager.connect_to_persistent_subscription(
          __MODULE__,
          subscriber,
          stream,
          group,
          allowed_in_flight_messages
        )
      end
    end
  end

  @doc """
  TODO
  """
  @callback start_link(config :: Keyword.t(), opts :: Keyword.t()) ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}

  @doc """
  TODO
  """
  @callback execute(message :: term(), correlation_id :: binary(), timeout :: integer()) :: term()

  @doc """
  TODO
  """
  @callback subscribe_to(stream :: String.t(), subscriber :: pid(), opts :: Keyword.t()) ::
              {:ok, pid}

  @doc """
  TODO
  """
  @callback unsubscribe(subscription :: pid()) :: :ok

  @doc """
  TODO
  """
  @callback read_and_stay_subscribed(
              stream :: String.t(),
              subscriber :: pid(),
              from_event_number :: non_neg_integer(),
              per_page :: pos_integer(),
              resolve_link_tos :: boolean(),
              require_master :: boolean()
            ) :: {:ok, pid()}

  @doc """
  Pings connected EventStore and should return `:pong` back.
  """
  @callback ping() :: :pong

  @doc """
  Spawns a persistent subscription.

  The persistent subscription will send events to the `subscriber` process in
  the form of `GenServer.cast/2`s in the shape of `{:on_event, event,
  correlation_id}`.

  See `Extreme.PersistentSubscription` for full details.
  """
  @callback connect_to_persistent_subscription(
              subscriber :: pid(),
              stream :: String.t(),
              group :: String.t(),
              allowed_in_flight_messages :: integer()
            ) :: {:ok, pid()}
end

defmodule Extreme.Messages.NewEvent do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: String.t(),
          data_content_type: integer,
          metadata_content_type: integer,
          data: String.t(),
          metadata: String.t()
        }
  defstruct [:event_id, :event_type, :data_content_type, :metadata_content_type, :data, :metadata]

  field(:event_id, 1, required: true, type: :bytes)
  field(:event_type, 2, required: true, type: :string)
  field(:data_content_type, 3, required: true, type: :int32)
  field(:metadata_content_type, 4, required: true, type: :int32)
  field(:data, 5, required: true, type: :bytes)
  field(:metadata, 6, optional: true, type: :bytes)
end

defmodule Extreme.Messages.EventRecord do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          event_number: integer,
          event_id: String.t(),
          event_type: String.t(),
          data_content_type: integer,
          metadata_content_type: integer,
          data: String.t(),
          metadata: String.t(),
          created: integer,
          created_epoch: integer
        }
  defstruct [
    :event_stream_id,
    :event_number,
    :event_id,
    :event_type,
    :data_content_type,
    :metadata_content_type,
    :data,
    :metadata,
    :created,
    :created_epoch
  ]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:event_number, 2, required: true, type: :int64)
  field(:event_id, 3, required: true, type: :bytes)
  field(:event_type, 4, required: true, type: :string)
  field(:data_content_type, 5, required: true, type: :int32)
  field(:metadata_content_type, 6, required: true, type: :int32)
  field(:data, 7, required: true, type: :bytes)
  field(:metadata, 8, optional: true, type: :bytes)
  field(:created, 9, optional: true, type: :int64)
  field(:created_epoch, 10, optional: true, type: :int64)
end

defmodule Extreme.Messages.ResolvedIndexedEvent do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event: Extreme.Messages.EventRecord.t(),
          link: Extreme.Messages.EventRecord.t()
        }
  defstruct [:event, :link]

  field(:event, 1, required: true, type: Extreme.Messages.EventRecord)
  field(:link, 2, optional: true, type: Extreme.Messages.EventRecord)
end

defmodule Extreme.Messages.ResolvedEvent do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event: Extreme.Messages.EventRecord.t(),
          link: Extreme.Messages.EventRecord.t(),
          commit_position: integer,
          prepare_position: integer
        }
  defstruct [:event, :link, :commit_position, :prepare_position]

  field(:event, 1, required: true, type: Extreme.Messages.EventRecord)
  field(:link, 2, optional: true, type: Extreme.Messages.EventRecord)
  field(:commit_position, 3, required: true, type: :int64)
  field(:prepare_position, 4, required: true, type: :int64)
end

defmodule Extreme.Messages.WriteEvents do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          expected_version: integer,
          events: [Extreme.Messages.NewEvent.t()],
          require_master: boolean
        }
  defstruct [:event_stream_id, :expected_version, :events, :require_master]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:expected_version, 2, required: true, type: :int64)
  field(:events, 3, repeated: true, type: Extreme.Messages.NewEvent)
  field(:require_master, 4, required: true, type: :bool)
end

defmodule Extreme.Messages.WriteEventsCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          message: String.t(),
          first_event_number: integer,
          last_event_number: integer,
          prepare_position: integer,
          commit_position: integer,
          current_version: integer
        }
  defstruct [
    :result,
    :message,
    :first_event_number,
    :last_event_number,
    :prepare_position,
    :commit_position,
    :current_version
  ]

  field(:result, 1, required: true, type: Extreme.Messages.OperationResult, enum: true)
  field(:message, 2, optional: true, type: :string)
  field(:first_event_number, 3, required: true, type: :int64)
  field(:last_event_number, 4, required: true, type: :int64)
  field(:prepare_position, 5, optional: true, type: :int64)
  field(:commit_position, 6, optional: true, type: :int64)
  field(:current_version, 7, optional: true, type: :int64)
end

defmodule Extreme.Messages.DeleteStream do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          expected_version: integer,
          require_master: boolean,
          hard_delete: boolean
        }
  defstruct [:event_stream_id, :expected_version, :require_master, :hard_delete]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:expected_version, 2, required: true, type: :int64)
  field(:require_master, 3, required: true, type: :bool)
  field(:hard_delete, 4, optional: true, type: :bool)
end

defmodule Extreme.Messages.DeleteStreamCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          message: String.t(),
          prepare_position: integer,
          commit_position: integer
        }
  defstruct [:result, :message, :prepare_position, :commit_position]

  field(:result, 1, required: true, type: Extreme.Messages.OperationResult, enum: true)
  field(:message, 2, optional: true, type: :string)
  field(:prepare_position, 3, optional: true, type: :int64)
  field(:commit_position, 4, optional: true, type: :int64)
end

defmodule Extreme.Messages.TransactionStart do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          expected_version: integer,
          require_master: boolean
        }
  defstruct [:event_stream_id, :expected_version, :require_master]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:expected_version, 2, required: true, type: :int64)
  field(:require_master, 3, required: true, type: :bool)
end

defmodule Extreme.Messages.TransactionStartCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          transaction_id: integer,
          result: integer,
          message: String.t()
        }
  defstruct [:transaction_id, :result, :message]

  field(:transaction_id, 1, required: true, type: :int64)
  field(:result, 2, required: true, type: Extreme.Messages.OperationResult, enum: true)
  field(:message, 3, optional: true, type: :string)
end

defmodule Extreme.Messages.TransactionWrite do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          transaction_id: integer,
          events: [Extreme.Messages.NewEvent.t()],
          require_master: boolean
        }
  defstruct [:transaction_id, :events, :require_master]

  field(:transaction_id, 1, required: true, type: :int64)
  field(:events, 2, repeated: true, type: Extreme.Messages.NewEvent)
  field(:require_master, 3, required: true, type: :bool)
end

defmodule Extreme.Messages.TransactionWriteCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          transaction_id: integer,
          result: integer,
          message: String.t()
        }
  defstruct [:transaction_id, :result, :message]

  field(:transaction_id, 1, required: true, type: :int64)
  field(:result, 2, required: true, type: Extreme.Messages.OperationResult, enum: true)
  field(:message, 3, optional: true, type: :string)
end

defmodule Extreme.Messages.TransactionCommit do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          transaction_id: integer,
          require_master: boolean
        }
  defstruct [:transaction_id, :require_master]

  field(:transaction_id, 1, required: true, type: :int64)
  field(:require_master, 2, required: true, type: :bool)
end

defmodule Extreme.Messages.TransactionCommitCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          transaction_id: integer,
          result: integer,
          message: String.t(),
          first_event_number: integer,
          last_event_number: integer,
          prepare_position: integer,
          commit_position: integer
        }
  defstruct [
    :transaction_id,
    :result,
    :message,
    :first_event_number,
    :last_event_number,
    :prepare_position,
    :commit_position
  ]

  field(:transaction_id, 1, required: true, type: :int64)
  field(:result, 2, required: true, type: Extreme.Messages.OperationResult, enum: true)
  field(:message, 3, optional: true, type: :string)
  field(:first_event_number, 4, required: true, type: :int64)
  field(:last_event_number, 5, required: true, type: :int64)
  field(:prepare_position, 6, optional: true, type: :int64)
  field(:commit_position, 7, optional: true, type: :int64)
end

defmodule Extreme.Messages.ReadEvent do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          event_number: integer,
          resolve_link_tos: boolean,
          require_master: boolean
        }
  defstruct [:event_stream_id, :event_number, :resolve_link_tos, :require_master]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:event_number, 2, required: true, type: :int64)
  field(:resolve_link_tos, 3, required: true, type: :bool)
  field(:require_master, 4, required: true, type: :bool)
end

defmodule Extreme.Messages.ReadEventCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          event: Extreme.Messages.ResolvedIndexedEvent.t(),
          error: String.t()
        }
  defstruct [:result, :event, :error]

  field(:result, 1,
    required: true,
    type: Extreme.Messages.ReadEventCompleted.ReadEventResult,
    enum: true
  )

  field(:event, 2, required: true, type: Extreme.Messages.ResolvedIndexedEvent)
  field(:error, 3, optional: true, type: :string)
end

defmodule Extreme.Messages.ReadEventCompleted.ReadEventResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:NotFound, 1)
  field(:NoStream, 2)
  field(:StreamDeleted, 3)
  field(:Error, 4)
  field(:AccessDenied, 5)
end

defmodule Extreme.Messages.ReadStreamEvents do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          from_event_number: integer,
          max_count: integer,
          resolve_link_tos: boolean,
          require_master: boolean
        }
  defstruct [:event_stream_id, :from_event_number, :max_count, :resolve_link_tos, :require_master]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:from_event_number, 2, required: true, type: :int64)
  field(:max_count, 3, required: true, type: :int32)
  field(:resolve_link_tos, 4, required: true, type: :bool)
  field(:require_master, 5, required: true, type: :bool)
end

defmodule Extreme.Messages.ReadStreamEventsCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          events: [Extreme.Messages.ResolvedIndexedEvent.t()],
          result: integer,
          next_event_number: integer,
          last_event_number: integer,
          is_end_of_stream: boolean,
          last_commit_position: integer,
          error: String.t()
        }
  defstruct [
    :events,
    :result,
    :next_event_number,
    :last_event_number,
    :is_end_of_stream,
    :last_commit_position,
    :error
  ]

  field(:events, 1, repeated: true, type: Extreme.Messages.ResolvedIndexedEvent)

  field(:result, 2,
    required: true,
    type: Extreme.Messages.ReadStreamEventsCompleted.ReadStreamResult,
    enum: true
  )

  field(:next_event_number, 3, required: true, type: :int64)
  field(:last_event_number, 4, required: true, type: :int64)
  field(:is_end_of_stream, 5, required: true, type: :bool)
  field(:last_commit_position, 6, required: true, type: :int64)
  field(:error, 7, optional: true, type: :string)
end

defmodule Extreme.Messages.ReadStreamEventsCompleted.ReadStreamResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:NoStream, 1)
  field(:StreamDeleted, 2)
  field(:NotModified, 3)
  field(:Error, 4)
  field(:AccessDenied, 5)
end

defmodule Extreme.Messages.ReadAllEvents do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          commit_position: integer,
          prepare_position: integer,
          max_count: integer,
          resolve_link_tos: boolean,
          require_master: boolean
        }
  defstruct [:commit_position, :prepare_position, :max_count, :resolve_link_tos, :require_master]

  field(:commit_position, 1, required: true, type: :int64)
  field(:prepare_position, 2, required: true, type: :int64)
  field(:max_count, 3, required: true, type: :int32)
  field(:resolve_link_tos, 4, required: true, type: :bool)
  field(:require_master, 5, required: true, type: :bool)
end

defmodule Extreme.Messages.ReadAllEventsCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          commit_position: integer,
          prepare_position: integer,
          events: [Extreme.Messages.ResolvedEvent.t()],
          next_commit_position: integer,
          next_prepare_position: integer,
          result: integer,
          error: String.t()
        }
  defstruct [
    :commit_position,
    :prepare_position,
    :events,
    :next_commit_position,
    :next_prepare_position,
    :result,
    :error
  ]

  field(:commit_position, 1, required: true, type: :int64)
  field(:prepare_position, 2, required: true, type: :int64)
  field(:events, 3, repeated: true, type: Extreme.Messages.ResolvedEvent)
  field(:next_commit_position, 4, required: true, type: :int64)
  field(:next_prepare_position, 5, required: true, type: :int64)

  field(:result, 6,
    optional: true,
    type: Extreme.Messages.ReadAllEventsCompleted.ReadAllResult,
    default: :Success,
    enum: true
  )

  field(:error, 7, optional: true, type: :string)
end

defmodule Extreme.Messages.ReadAllEventsCompleted.ReadAllResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:NotModified, 1)
  field(:Error, 2)
  field(:AccessDenied, 3)
end

defmodule Extreme.Messages.CreatePersistentSubscription do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_group_name: String.t(),
          event_stream_id: String.t(),
          resolve_link_tos: boolean,
          start_from: integer,
          message_timeout_milliseconds: integer,
          record_statistics: boolean,
          live_buffer_size: integer,
          read_batch_size: integer,
          buffer_size: integer,
          max_retry_count: integer,
          prefer_round_robin: boolean,
          checkpoint_after_time: integer,
          checkpoint_max_count: integer,
          checkpoint_min_count: integer,
          subscriber_max_count: integer,
          named_consumer_strategy: String.t()
        }
  defstruct [
    :subscription_group_name,
    :event_stream_id,
    :resolve_link_tos,
    :start_from,
    :message_timeout_milliseconds,
    :record_statistics,
    :live_buffer_size,
    :read_batch_size,
    :buffer_size,
    :max_retry_count,
    :prefer_round_robin,
    :checkpoint_after_time,
    :checkpoint_max_count,
    :checkpoint_min_count,
    :subscriber_max_count,
    :named_consumer_strategy
  ]

  field(:subscription_group_name, 1, required: true, type: :string)
  field(:event_stream_id, 2, required: true, type: :string)
  field(:resolve_link_tos, 3, required: true, type: :bool)
  field(:start_from, 4, required: true, type: :int64)
  field(:message_timeout_milliseconds, 5, required: true, type: :int32)
  field(:record_statistics, 6, required: true, type: :bool)
  field(:live_buffer_size, 7, required: true, type: :int32)
  field(:read_batch_size, 8, required: true, type: :int32)
  field(:buffer_size, 9, required: true, type: :int32)
  field(:max_retry_count, 10, required: true, type: :int32)
  field(:prefer_round_robin, 11, required: true, type: :bool)
  field(:checkpoint_after_time, 12, required: true, type: :int32)
  field(:checkpoint_max_count, 13, required: true, type: :int32)
  field(:checkpoint_min_count, 14, required: true, type: :int32)
  field(:subscriber_max_count, 15, required: true, type: :int32)
  field(:named_consumer_strategy, 16, optional: true, type: :string)
end

defmodule Extreme.Messages.DeletePersistentSubscription do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_group_name: String.t(),
          event_stream_id: String.t()
        }
  defstruct [:subscription_group_name, :event_stream_id]

  field(:subscription_group_name, 1, required: true, type: :string)
  field(:event_stream_id, 2, required: true, type: :string)
end

defmodule Extreme.Messages.UpdatePersistentSubscription do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_group_name: String.t(),
          event_stream_id: String.t(),
          resolve_link_tos: boolean,
          start_from: integer,
          message_timeout_milliseconds: integer,
          record_statistics: boolean,
          live_buffer_size: integer,
          read_batch_size: integer,
          buffer_size: integer,
          max_retry_count: integer,
          prefer_round_robin: boolean,
          checkpoint_after_time: integer,
          checkpoint_max_count: integer,
          checkpoint_min_count: integer,
          subscriber_max_count: integer,
          named_consumer_strategy: String.t()
        }
  defstruct [
    :subscription_group_name,
    :event_stream_id,
    :resolve_link_tos,
    :start_from,
    :message_timeout_milliseconds,
    :record_statistics,
    :live_buffer_size,
    :read_batch_size,
    :buffer_size,
    :max_retry_count,
    :prefer_round_robin,
    :checkpoint_after_time,
    :checkpoint_max_count,
    :checkpoint_min_count,
    :subscriber_max_count,
    :named_consumer_strategy
  ]

  field(:subscription_group_name, 1, required: true, type: :string)
  field(:event_stream_id, 2, required: true, type: :string)
  field(:resolve_link_tos, 3, required: true, type: :bool)
  field(:start_from, 4, required: true, type: :int64)
  field(:message_timeout_milliseconds, 5, required: true, type: :int32)
  field(:record_statistics, 6, required: true, type: :bool)
  field(:live_buffer_size, 7, required: true, type: :int32)
  field(:read_batch_size, 8, required: true, type: :int32)
  field(:buffer_size, 9, required: true, type: :int32)
  field(:max_retry_count, 10, required: true, type: :int32)
  field(:prefer_round_robin, 11, required: true, type: :bool)
  field(:checkpoint_after_time, 12, required: true, type: :int32)
  field(:checkpoint_max_count, 13, required: true, type: :int32)
  field(:checkpoint_min_count, 14, required: true, type: :int32)
  field(:subscriber_max_count, 15, required: true, type: :int32)
  field(:named_consumer_strategy, 16, optional: true, type: :string)
end

defmodule Extreme.Messages.UpdatePersistentSubscriptionCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          reason: String.t()
        }
  defstruct [:result, :reason]

  field(:result, 1,
    required: true,
    type:
      Extreme.Messages.UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult,
    default: :Success,
    enum: true
  )

  field(:reason, 2, optional: true, type: :string)
end

defmodule Extreme.Messages.UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:DoesNotExist, 1)
  field(:Fail, 2)
  field(:AccessDenied, 3)
end

defmodule Extreme.Messages.CreatePersistentSubscriptionCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          reason: String.t()
        }
  defstruct [:result, :reason]

  field(:result, 1,
    required: true,
    type:
      Extreme.Messages.CreatePersistentSubscriptionCompleted.CreatePersistentSubscriptionResult,
    default: :Success,
    enum: true
  )

  field(:reason, 2, optional: true, type: :string)
end

defmodule Extreme.Messages.CreatePersistentSubscriptionCompleted.CreatePersistentSubscriptionResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:AlreadyExists, 1)
  field(:Fail, 2)
  field(:AccessDenied, 3)
end

defmodule Extreme.Messages.DeletePersistentSubscriptionCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          reason: String.t()
        }
  defstruct [:result, :reason]

  field(:result, 1,
    required: true,
    type:
      Extreme.Messages.DeletePersistentSubscriptionCompleted.DeletePersistentSubscriptionResult,
    default: :Success,
    enum: true
  )

  field(:reason, 2, optional: true, type: :string)
end

defmodule Extreme.Messages.DeletePersistentSubscriptionCompleted.DeletePersistentSubscriptionResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:DoesNotExist, 1)
  field(:Fail, 2)
  field(:AccessDenied, 3)
end

defmodule Extreme.Messages.ConnectToPersistentSubscription do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_id: String.t(),
          event_stream_id: String.t(),
          allowed_in_flight_messages: integer
        }
  defstruct [:subscription_id, :event_stream_id, :allowed_in_flight_messages]

  field(:subscription_id, 1, required: true, type: :string)
  field(:event_stream_id, 2, required: true, type: :string)
  field(:allowed_in_flight_messages, 3, required: true, type: :int32)
end

defmodule Extreme.Messages.PersistentSubscriptionAckEvents do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_id: String.t(),
          processed_event_ids: [String.t()]
        }
  defstruct [:subscription_id, :processed_event_ids]

  field(:subscription_id, 1, required: true, type: :string)
  field(:processed_event_ids, 2, repeated: true, type: :bytes)
end

defmodule Extreme.Messages.PersistentSubscriptionNakEvents do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          subscription_id: String.t(),
          processed_event_ids: [String.t()],
          message: String.t(),
          action: integer
        }
  defstruct [:subscription_id, :processed_event_ids, :message, :action]

  field(:subscription_id, 1, required: true, type: :string)
  field(:processed_event_ids, 2, repeated: true, type: :bytes)
  field(:message, 3, optional: true, type: :string)

  field(:action, 4,
    required: true,
    type: Extreme.Messages.PersistentSubscriptionNakEvents.NakAction,
    default: :Unknown,
    enum: true
  )
end

defmodule Extreme.Messages.PersistentSubscriptionNakEvents.NakAction do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Unknown, 0)
  field(:Park, 1)
  field(:Retry, 2)
  field(:Skip, 3)
  field(:Stop, 4)
end

defmodule Extreme.Messages.PersistentSubscriptionConfirmation do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          last_commit_position: integer,
          subscription_id: String.t(),
          last_event_number: integer
        }
  defstruct [:last_commit_position, :subscription_id, :last_event_number]

  field(:last_commit_position, 1, required: true, type: :int64)
  field(:subscription_id, 2, required: true, type: :string)
  field(:last_event_number, 3, optional: true, type: :int64)
end

defmodule Extreme.Messages.PersistentSubscriptionStreamEventAppeared do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event: Extreme.Messages.ResolvedIndexedEvent.t(),
          retryCount: integer
        }
  defstruct [:event, :retryCount]

  field(:event, 1, required: true, type: Extreme.Messages.ResolvedIndexedEvent)
  field(:retryCount, 2, optional: true, type: :int32)
end

defmodule Extreme.Messages.SubscribeToStream do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event_stream_id: String.t(),
          resolve_link_tos: boolean
        }
  defstruct [:event_stream_id, :resolve_link_tos]

  field(:event_stream_id, 1, required: true, type: :string)
  field(:resolve_link_tos, 2, required: true, type: :bool)
end

defmodule Extreme.Messages.SubscriptionConfirmation do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          last_commit_position: integer,
          last_event_number: integer
        }
  defstruct [:last_commit_position, :last_event_number]

  field(:last_commit_position, 1, required: true, type: :int64)
  field(:last_event_number, 2, optional: true, type: :int64)
end

defmodule Extreme.Messages.StreamEventAppeared do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          event: Extreme.Messages.ResolvedEvent.t()
        }
  defstruct [:event]

  field(:event, 1, required: true, type: Extreme.Messages.ResolvedEvent)
end

defmodule Extreme.Messages.UnsubscribeFromStream do
  @moduledoc false
  use Protobuf, syntax: :proto2

  defstruct []
end

defmodule Extreme.Messages.SubscriptionDropped do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          reason: integer
        }
  defstruct [:reason]

  field(:reason, 1,
    optional: true,
    type: Extreme.Messages.SubscriptionDropped.SubscriptionDropReason,
    default: :Unsubscribed,
    enum: true
  )
end

defmodule Extreme.Messages.SubscriptionDropped.SubscriptionDropReason do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Unsubscribed, 0)
  field(:AccessDenied, 1)
  field(:NotFound, 2)
  field(:PersistentSubscriptionDeleted, 3)
  field(:SubscriberMaxCountReached, 4)
end

defmodule Extreme.Messages.NotHandled do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          reason: integer,
          additional_info: String.t()
        }
  defstruct [:reason, :additional_info]

  field(:reason, 1,
    required: true,
    type: Extreme.Messages.NotHandled.NotHandledReason,
    enum: true
  )

  field(:additional_info, 2, optional: true, type: :bytes)
end

defmodule Extreme.Messages.NotHandled.MasterInfo do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          external_tcp_address: String.t(),
          external_tcp_port: integer,
          external_http_address: String.t(),
          external_http_port: integer,
          external_secure_tcp_address: String.t(),
          external_secure_tcp_port: integer
        }
  defstruct [
    :external_tcp_address,
    :external_tcp_port,
    :external_http_address,
    :external_http_port,
    :external_secure_tcp_address,
    :external_secure_tcp_port
  ]

  field(:external_tcp_address, 1, required: true, type: :string)
  field(:external_tcp_port, 2, required: true, type: :int32)
  field(:external_http_address, 3, required: true, type: :string)
  field(:external_http_port, 4, required: true, type: :int32)
  field(:external_secure_tcp_address, 5, optional: true, type: :string)
  field(:external_secure_tcp_port, 6, optional: true, type: :int32)
end

defmodule Extreme.Messages.NotHandled.NotHandledReason do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:NotReady, 0)
  field(:TooBusy, 1)
  field(:NotMaster, 2)
end

defmodule Extreme.Messages.ScavengeDatabase do
  @moduledoc false
  use Protobuf, syntax: :proto2

  defstruct []
end

defmodule Extreme.Messages.ScavengeDatabaseCompleted do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          result: integer,
          error: String.t(),
          total_time_ms: integer,
          total_space_saved: integer
        }
  defstruct [:result, :error, :total_time_ms, :total_space_saved]

  field(:result, 1,
    required: true,
    type: Extreme.Messages.ScavengeDatabaseCompleted.ScavengeResult,
    enum: true
  )

  field(:error, 2, optional: true, type: :string)
  field(:total_time_ms, 3, required: true, type: :int32)
  field(:total_space_saved, 4, required: true, type: :int64)
end

defmodule Extreme.Messages.ScavengeDatabaseCompleted.ScavengeResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:InProgress, 1)
  field(:Failed, 2)
end

defmodule Extreme.Messages.IdentifyClient do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
          version: integer,
          connection_name: String.t()
        }
  defstruct [:version, :connection_name]

  field(:version, 1, required: true, type: :int32)
  field(:connection_name, 2, optional: true, type: :string)
end

defmodule Extreme.Messages.ClientIdentified do
  @moduledoc false
  use Protobuf, syntax: :proto2

  defstruct []
end

defmodule Extreme.Messages.OperationResult do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field(:Success, 0)
  field(:PrepareTimeout, 1)
  field(:CommitTimeout, 2)
  field(:ForwardTimeout, 3)
  field(:WrongExpectedVersion, 4)
  field(:StreamDeleted, 5)
  field(:InvalidTransaction, 6)
  field(:AccessDenied, 7)
end

defmodule Extreme.Messages do
  @moduledoc """
  Messages are based on  official proto file: 
  https://github.com/EventStore/EventStore/blob/master/src/Protos/ClientAPI/ClientMessageDtos.proto
  + ReadStreamEventsBackward message (that works but is missing in their proto file)
  """
  use Protobuf,
    from: Path.expand("../../include/event_store.proto", __DIR__),
    use_package_names: true
end

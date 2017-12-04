defmodule Extreme.Msg do
  if Application.get_env(:extreme, :protocol_version, 3) >= 4 do
    use Protobuf, from: Path.expand("../include/event_store-4.proto", __DIR__)
  else
    use Protobuf, from: Path.expand("../include/event_store.proto", __DIR__)
  end
end

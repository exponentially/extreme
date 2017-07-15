defmodule Extreme.Msg do
  if System.get_env("EXTREME_ES_VERSION") == "4" do
    use Protobuf, from: Path.expand("../include/event_store-4.proto", __DIR__)
  else
    use Protobuf, from: Path.expand("../include/event_store.proto", __DIR__)
  end
end

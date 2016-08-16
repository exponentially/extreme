defmodule Extreme.MessageResolverNew do
  all   = Extreme.MessageCommandReader.tcp_commands
  plain = all |> Enum.filter(fn({_,b,_})-> b == false end)
  proto = all |> Enum.filter(fn({_,b,_})-> b != false end)
  # leftover protos without automatic mapping to command
  # see command_reader tests for details
  special = [
    {:read_stream_events_forward, Extreme.Messages.ReadStreamEvents, 178},
    {:read_stream_events_forward_completed, Extreme.Messages.ReadStreamEventsCompleted, 179},
    {:read_stream_events_backward, Extreme.Messages.ReadStreamEvents, 180},
    {:read_stream_events_backward_completed, Extreme.Messages.ReadStreamEventsCompleted, 181},
    {:read_all_events_forward, Extreme.Messages.ReadAllEvents, 182},
    {:read_all_events_forward_completed, Extreme.Messages.ReadAllEventsCompleted, 183},
    {:read_all_events_backward, Extreme.Messages.ReadAllEvents, 184},
    {:read_all_events_backward_completed, Extreme.Messages.ReadAllEventsCompleted, 185},
  ]

  # first generate all decode functions (bit -> human)
  for {type, proto_msg, bit} <- plain do
    def decode_cmd(unquote(bit)) do
      unquote(type)
    end
  end
  for {type, proto_msg, bit} <- (proto ++ special) do
    def decode_cmd(unquote(bit)) do
      unquote(proto_msg)
    end
  end

  # now reverse (human -> bit)
  for {type, proto_msg, bit} <- plain do
    def encode_cmd(unquote(type)) do
      unquote(bit)
    end
  end
  for {type, proto_msg, bit} <- proto do
    def encode_cmd(unquote(proto_msg)) do
      unquote(bit)
    end
  end

  # # not sure if this is necessary, eg. mapping Extreme.Messages.ReadAllEvents to a bit won't work...
  # for {type, proto_msg, bit} <- special do
  #   def encode_cmd(unquote(type), unquote(proto_msg)) do
  #     unquote(bit)
  #   end
  # end
end

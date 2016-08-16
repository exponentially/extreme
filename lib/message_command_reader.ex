defmodule Extreme.MessageCommandReader do
  @moduledoc """
  used only for compile-time generation of encode / decode functions in message resolver
  """
  @src Path.expand("../include/TcpCommands.cs", __DIR__)
  @available_proto_modules Extreme.Messages.defs
    |> Enum.filter(fn({{t, _}, _})-> t == :msg end)
    |> Enum.map(fn({{_, m}, _})-> m end)
    |> Enum.sort(fn(a, b)-> Atom.to_string(a) < Atom.to_string(b) end)

  @doc """
  all modules defined by the event_store.proto file
  """
  def available_proto_modules do
    @available_proto_modules
  end

  @doc """
  TCP commands generated from the `include/TcpCommands.cs` file
  possible items
    - `{:heartbeat_response_command, false, 2}` (no proto matched)
    - `{:write_events_completed, Extreme.Messages.WriteEventsCompleted, 131}`
  """
  def tcp_commands do
    @src
    |> File.read
    |> ok
    |> String.split("\n")
    |> Enum.filter(&(&1 =~ ~r/=/))
    |> Enum.reject(&(&1 =~ ~r/\/\//))
    |> Enum.map(&split/1)
    |> Enum.map(&convert/1)
  end

  defp ok({:ok, v}), do: v

  defp split(line) do
    line
    |> String.replace(",", "")
    |> String.split("=")
    |> Enum.map(&(String.strip(&1)))
  end

  defp convert([cmd, code]) do
    {to_command(cmd), to_proto(cmd), to_code(code)}
  end

  defp to_code("0x" <> code) when is_binary(code) do
    code |> :erlang.binary_to_integer(16)
  end

  defp to_command(cmd) when is_binary(cmd) do
    cmd |> Macro.underscore |> String.to_atom
  end

  defp to_proto(cmd) when is_binary(cmd) do
    mod = to_module(cmd)
    case mod in available_proto_modules do
      true  -> mod
      false -> false
    end
  end

  defp to_module(cmd) do
    "Extreme.Messages.#{cmd}" |> Code.eval_string  |> elem(0)
  end
end

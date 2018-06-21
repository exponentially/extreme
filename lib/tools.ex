defmodule Extreme.Tools do
  def gen_uuid do
    Keyword.get(UUID.info!(UUID.uuid1()), :binary, :undefined)
  end

  def normalize_port(port) when is_binary(port), do: String.to_integer(port)
  def normalize_port(port), do: port
end

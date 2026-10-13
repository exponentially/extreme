defmodule Extreme.Tools do
  @moduledoc """
  Set of tool functions for internal library use.
  """

  # jason is an optional dependency, needed only for metadata and cluster gossip.
  @compile {:no_warn_undefined, Jason}

  @doc """
  Cast the provided value to an atom if appropriate.
  If the provided value is a string, convert it to an atom, otherwise return it as-is.
  """
  def cast_to_atom(value) when is_binary(value), do: String.to_atom(value)
  def cast_to_atom(value), do: value

  @doc """
  Converts value to integer if it is binary or returns it as-is
  """
  def cast_to_integer(value) when is_binary(value), do: String.to_integer(value)
  def cast_to_integer(value), do: value

  @doc """
  Generates a new UUIDv7 (RFC 9562) as a 16-byte binary: unix time in milliseconds,
  then random bits, so ids sort by creation time.
  """
  @spec generate_uuid() :: uuid :: <<_::128>>
  def generate_uuid do
    <<rand_a::12, rand_b::62, _unused::6>> = :crypto.strong_rand_bytes(10)

    <<System.os_time(:millisecond)::48, 7::4, rand_a::12, 0b10::2, rand_b::62>>
  end

  @doc "Encodes `term` as JSON with the optional `jason` dependency."
  @spec encode_json!(term :: term()) :: json :: String.t()
  def encode_json!(term), do: Jason.encode!(term)

  @doc "Decodes `json` with the optional `jason` dependency."
  @spec decode_json(json :: String.t()) :: {:ok, decoded :: term()} | {:error, reason :: term()}
  def decode_json(json), do: Jason.decode(json)
end

defmodule Extreme.Tools do
  @moduledoc """
  Set of tool functions for internal library use.
  """

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
  Generates new UUID1 as binary.
  """
  def generate_uuid,
    do: UUID.uuid1() |> UUID.string_to_binary!()
end

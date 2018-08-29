defmodule Extreme.Configuration do
  @moduledoc """
  Set of functions for retrieving configuration value with correct type
  """

  alias Extreme.Tools

  @doc """
  Returns `:db_type` value from `configuration` as `atom`.
  If one is not specified, defaults to `:node`.
  """
  def get_db_type(configuration) do
    configuration
    |> Keyword.get(:db_type, :node)
    |> Tools.cast_to_atom()
  end

  @doc """
  Returns `:host` value from `configuration` as charlist.
  If one is not specified raises exception.
  """
  def get_host(configuration) do
    configuration
    |> Keyword.fetch!(:host)
    |> String.to_charlist()
  end

  @doc """
  Returns `:port` value from `configuration` as `integer`.
  If one is not specified raises exception.
  """
  def get_port(configuration) do
    configuration
    |> Keyword.fetch!(:port)
    |> Tools.cast_to_integer()
  end

  @doc """
  Returns credentials part of EventStore request based on `:username` and `:password`
  fields in `configuration`. In any of those is not specified raises exception.
  """
  def prepare_credentials(configuration) do
    user = Keyword.fetch!(configuration, :username)
    pass = Keyword.fetch!(configuration, :password)

    user_len = byte_size(user)
    pass_len = byte_size(pass)

    <<user_len::size(8)>> <> user <> <<pass_len::size(8)>> <> pass
  end

  @doc """
  Returns `:connection_name` from `configuration` as binary.
  If one is not specified defaults to "Extreme".
  """
  def get_connection_name(configuration) do
    configuration
    |> Keyword.get(:connection_name, "Extreme")
    |> to_string()
  end

  @doc """
  Returns `:ping_interval` from `configuration` as integer.
  If one is not specified defaults to 1_000
  """
  def get_ping_interval(configuration) do
    configuration
    |> Keyword.get(:ping_interval, 1_000)
    |> Tools.cast_to_integer()
  end
end

defmodule Extreme.ConnectionImpl do
  @moduledoc """
  Set of connection related functions meant to be used from `Extreme.Connection` only!
  """
  alias Extreme.RequestManager
  alias Extreme.Connection.State

  require Logger

  def execute(message, %State{transport: :tcp, socket: socket}) do
    :gen_tcp.send(socket, message)
  end

  def execute(message, %State{transport: :ssl, socket: socket}) do
    :ssl.send(socket, message)
  end

  def receive_package(pkg, %State{received_data: received_data} = state) do
    set_active_once(state)
    state = _process_package(state, received_data <> pkg)
    {:ok, state}
  end

  defp set_active_once(%State{transport: :tcp, socket: socket}),
    do: :inet.setopts(socket, active: :once)

  defp set_active_once(%State{transport: :ssl, socket: socket}),
    do: :ssl.setopts(socket, active: :once)

  defp _process_package(
         state,
         <<message_length::32-unsigned-little-integer, content::binary-size(message_length),
           rest::binary>>
       ) do
    # Handle binary data containing zero, one or many messages
    # All messages start with a 32 bit unsigned little endian integer of the content length + a binary body of that size
    :ok = RequestManager.process_server_message(state.base_name, content)
    _process_package(state, rest)
  end

  # No full message left, keep state in GenServer to reprocess once more data arrives
  defp _process_package(state, package_with_incomplete_message),
    do: %{state | received_data: package_with_incomplete_message}
end

defmodule ExtremeTest.DB do
  def start_link(name \\ :db, start_from \\ -1),
    do: Agent.start_link(fn -> %{start_from: start_from} end, name: name)

  def get_last_event(name \\ :db, listener, stream),
    do: Agent.get(name, fn state -> Map.get(state, {listener, stream}, state[:start_from]) end)

  def ack_event(name \\ :db, listener, stream, event_number),
    do: Agent.update(name, fn state -> Map.put(state, {listener, stream}, event_number) end)

  def in_transaction(fun), do: fun.()
end

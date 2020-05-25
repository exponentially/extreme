defmodule Extreme.ReadOnlyTest do
  use ExUnit.Case

  alias ExtremeTest.Helpers

  defmodule ReadOnlyClient do
    use Extreme
  end

  describe "given an EventStore connection is configured as read-only" do
    setup do
      {:ok, client_pid} =
        :extreme
        |> Application.get_env(TestConn)
        |> Keyword.put(:read_only, true)
        |> ReadOnlyClient.start_link()

      on_exit(fn -> shutdown_client_module(client_pid) end)

      :ok
    end

    test """
    when attempting to write events
    then the execution is refused with reason :read_only
    """ do
      assert Helpers.write_events() |> ReadOnlyClient.execute() == {:error, :read_only}
    end

    test """
    when attempting to delete a stream
    then the execution is refused with reason :read_only
    """ do
      delete_stream_result =
        Helpers.random_stream_name()
        |> Helpers.delete_stream(true)
        |> ReadOnlyClient.execute()

      assert delete_stream_result == {:error, :read_only}
    end
  end

  describe "given a stream contains events and a connection is configured as read-only" do
    setup do
      {:ok, client_pid} =
        :extreme
        |> Application.get_env(TestConn)
        |> Keyword.put(:read_only, true)
        |> ReadOnlyClient.start_link()

      stream = Helpers.random_stream_name()

      {:ok, %{result: :success}} =
        stream
        |> Helpers.write_events()
        |> TestConn.execute()

      on_exit(fn ->
        Helpers.delete_stream(stream, false) |> TestConn.execute()
        shutdown_client_module(client_pid)
      end)

      [stream: stream]
    end

    test """
         when attempting to read events via the read only client
         then the events may be read
         """,
         c do
      assert {:ok, %Extreme.Messages.ReadStreamEventsCompleted{}} =
               Helpers.read_events(c.stream) |> ReadOnlyClient.execute()
    end
  end

  defp shutdown_client_module(client_pid) do
    client_ref = Process.monitor(client_pid)
    Process.exit(client_pid, :shutdown)

    # a useful alternative to `Process.sleep/1`
    # ensures that the read-only client module is fully shut-down before
    # moving on to the next test
    :ok =
      receive do
        {:DOWN, ^client_ref, _, _, _} -> :ok
      end
  end
end

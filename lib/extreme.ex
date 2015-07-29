defmodule Extreme do
  use GenServer

  ## Client API

  def start_link(host \\ "localhost", port \\ 1113, opts \\[]) do
    GenServer.start_link __MODULE__, {host, port}, opts
  end


  ## Server Callbacks

  def init({host, port}) do
    opts = [:binary, active: false]
    {:ok, socket} = String.to_char_list(host)
                    |> :gen_tcp.connect(port, opts)
    {:ok, %{socket: socket}}
  end
end

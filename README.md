# Extreme

Erlang/Elixir TCP client for [Event Store](http://geteventstore.com/).

This version is tested with EventStore 3.0.5 through 3.3.0.

## INSTALL

Add Extreme as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:extreme, "~> 0.4.3"}]
end
```

In order to deploy your app using `exrm` you should also update your application list to include `:extreme`:

```elixir
def application do
  [applications: [:extreme]]
end
```

Extreme includes all its dependencies so you don't have to name them separately.

After you are done, run `mix deps.get` in your shell to fetch and compile Extreme and its dependencies.


## USAGE

The best way to understand how adapter should be used is by investigating `test/extreme_test.exs` file, 
but we'll try to explain some details in here as well.

Extreme is implemented using GenServer and is OTP compatible. 
If client is disconnected from server we are not trying to reconnect, instead you should rely on your supervisor. 
For example:

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, :ok
  end

  @event_store MyApp.EventStore
  
  def init(:ok) do
    event_store_settings = Application.get_env :my_app, :event_store

    children = [
      worker(Extreme, [event_store_settings, [name: @event_store]]),
      # ... other workers / supervisors
    ]
    supervise children, strategy: :one_for_one
  end
end
```

You can manually start adapter as well (as you can see in test file):

```elixir
{:ok, server} = Application.get_env(:extreme, :event_store) |> Extreme.start_link
```

From now on, `server` pid is used for further communication. Since we are relying on supervisor to reconnect,
it is wise to name `server` as we did in example above.


### MODES

Extreme can connect to single ES node or to cluster specified with node IPs and ports.

Example for connecting to single node:

```elixir
config :extreme, :event_store,
  db_type: :node, 
  host: "localhost", 
  port: 1113, 
  username: "admin", 
  password: "changeit",
  reconnect_delay: 2_000,
  max_attempts: :infinity
```

* `db_type` - defaults to :node, thus it can be omitted
* `host` - check EXT IP setting of your EventStore
* `port` - check EXT TCP PORT setting of your EventStore
* `reconnect_delay` - in ms. Defaults to 1_000. If tcp connection fails this is how long it will wait for reconnection.
* `max_attempts` - Defaults to :infinity. Specifies how many times we'll try to connect to EventStore


Example for connecting to cluster:

```elixir
config :extreme, :event_store,
  db_type: :cluster,
  gossip_timeout: 300,
  nodes: [
    %{host: "10.10.10.29", port: 2113},
    %{host: "10.10.10.28", port: 2113},
    %{host: "10.10.10.30", port: 2113}
  ],
  username: "admin", 
  password: "changeit"
```

* `gossip_timeout` - in ms. Defaults to 1_000. We are iterating through `nodes` list, asking for cluster member details.
This setting represents timeout for gossip response before we are asking next node from `nodes` list for cluster details.
* `nodes` - Mandatory for cluster connection. Represents list of nodes in the cluster as we know it
  * `host` - should be EXT IP setting of your EventStore node
  * `port` - should be EXT HTTP PORT setting of your EventStore node

When `cluster` mode is used, adapter goes thru `nodes` list and tries to gossip with node one after another
until it gets response about nodes. Based on nodes information from that response it ranks their statuses and chooses
the best candidate to connect to. For the way ranking is done, take a look at `lib/cluster_connection.ex`:

```elixir
defp rank_state("Master"), do: 1
defp rank_state("PreMaster"), do: 2
defp rank_state("Slave"), do: 3
defp rank_state("Clone"), do: 4
defp rank_state("CatchingUp"), do: 5
defp rank_state("PreReplica"), do: 6
defp rank_state("Unknown"), do: 7
defp rank_state("Initializing"), do: 8
```

Once client is disconnected from EventStore, supervisor should respawn it and connection starts over again.

### Communication

EventStore uses ProtoBuf for taking requests and sending responses back. 
We are using [exprotobuf](https://github.com/bitwalker/exprotobuf) to deal with them. 
List and specification of supported protobuf messages can be found in `include/event_store.proto` file.

Instead of wrapping each and every request in elixir function, we are using `execute/2` function that takes server pid and request message:

```elixir
assert {:ok, response} = Extreme.execute server, write_events
```

where `write_events` can be helper function like:

```elixir
  alias Extreme.Messages, as: ExMsg

  defp write_events(stream \\ "people", events \\ [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]) do
    proto_events = Enum.map(events, fn event -> 
      ExMsg.NewEvent.new(
        event_id: Extreme.Tools.gen_uuid(),
        event_type: to_string(event.__struct__),
        data_content_type: 0,
        metadata_content_type: 0,
        data: :erlang.term_to_binary(event),
        meta: ""
      ) end)
    ExMsg.WriteEvents.new(
      event_stream_id: stream, 
      expected_version: -2,
      events: proto_events,
      require_master: false
    )
  end
```

This way you can fine tune your requests, i.e. choose your serialization. We are using erlang serialization in this case
`data: :erlang.term_to_binary(event)`, but you can do whatever suites you. 
For more information about protobuf messages EventStore uses, 
take a look at their [documentation](http://docs.geteventstore.com) or for common use cases 
you can check `test/extreme_test.exs` file.


### Subscriptions

`Extreme.subscribe_to/3` function is used to get notified on new events on particular stream. 
This way subscriber, in next example `self`, will get message `{:on_event, push_message}` when new event is added to stream
_people_.

```elixir
def subscribe(server, stream \\ "people"), do: Extreme.subscribe_to(server, self, stream)

def handle_info({:on_event, event}, state) do
  Logger.debug "New event added to stream 'people': #{inspect event}"
  {:noreply, state}
end
```


`Extreme.read_and_stay_subscribed/7` is used to read existing events and stay subscribed on stream.

```elixir
defmodule MyApp.StreamSubscriber
  use GenServer

  def start_link(extreme, last_processed_event), do: GenServer.start_link __MODULE__, {extreme, last_processed_event}

  def init({extreme, last_processed_event}) do
    stream = "people"
    state = %{ event_store: extreme, stream: stream, last_event: last_processed_event }
    GenServer.cast self, :subscribe
    {:ok, state}
  end

  def handle_cast(:subscribe, state) do
    # read only unprocessed events and stay subscribed
    {:ok, subscription} = Extreme.read_and_stay_subscribed state.event_store, self, state.stream, state.last_event + 1
    # we want to monitor when subscription is crashed so we can resubscribe
    ref = Process.monitor subscription
    {:noreply, %{state|subscription_ref: ref}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{subscription_ref: ref} = state) do
    GenServer.cast self, :subscribe
    {:noreply, state}
  end
  def handle_info({:on_event, push}, state) do
    push.event.data
    |> :erlang.binary_to_term 
    |> process_event
    event_number = push.link.event_number
    :ok = update_last_event state.stream, event_number
    {:noreply, %{state|last_event: event_number}}
  end
  def handle_info(_msg, state), do: {:noreply, state}

  defp process_event(event), do: IO.puts("Do something with #{inspect event}")
  defp update_last_event(_stream, _event_number), do: IO.puts("Persist last processed event_number for stream")
end
```

This way unprocessed events will be sent by Extreme, using `{:on_event, push}` message. 
After all persisted messages are sent, new messages will be sent the same way as they arrive to stream.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Licensed under The MIT License.

# Extreme

[![Build Status](https://travis-ci.org/exponentially/extreme.svg?branch=v1.0.0)](https://travis-ci.org/exponentially/extreme)
[![Hex version](https://img.shields.io/hexpm/v/extreme.svg "Hex version")](https://hex.pm/packages/extreme)
[![InchCI](https://inch-ci.org/github/exponentially/extreme.svg?branch=v1.0.0)](https://inch-ci.org/github/exponentially/extreme)
[![Coverage Status](https://coveralls.io/repos/github/exponentially/extreme/badge.svg?branch=v1.0.0)](https://coveralls.io/github/exponentially/extreme?branch=v1.0.0)


Erlang/Elixir TCP client for [Event Store](http://geteventstore.com/).

This version is tested with EventStore 3.9.3, 4.1.1 and 5.0.1, Elixir 1.5 - 1.10 and Erlang/OTP 19.3 - 22.2

## INSTALL

Add Extreme as a dependency in your `mix.exs` file.

```elixir
def deps do
  [{:extreme, "~> 1.0.0-rc1"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile Extreme and its dependencies.

### EventStore v4 and later note

Starting from EventStore version 4.0 there are some upgrades to communication protocol. Event number size is changed to 64bits
and there is new messages `IdentifyClient` and `ClientIdentified`. Since we would like to keep backward compatibility with older v3 protocol,
we introduced new configuration for `:extreme` application, where you have to set `:protocol_version` equal to `4` if you want to use new protocol, default is `3`.
Below is exact line you have to add in you application config file in order to activate new protocol:

```elixir
config :extreme, :protocol_version, 4
```

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
  connection_name: :my_app,
  max_attempts: :infinity
```

* `db_type` - defaults to :node, thus it can be omitted
* `host` - check EXT IP setting of your EventStore
* `port` - check EXT TCP PORT setting of your EventStore
* `reconnect_delay` - in ms. Defaults to 1_000. If tcp connection fails this is how long it will wait for reconnection.
* `connection_name` - Optional param introduced in EventStore 4. Connection can be identified by this name on ES UI
* `max_attempts` - Defaults to :infinity. Specifies how many times we'll try to connect to EventStore


Example for connecting to cluster:

```elixir
config :extreme, :event_store,
  db_type: :cluster,
  gossip_timeout: 300,
  mode: :read,
  nodes: [
    %{host: "10.10.10.29", port: 2113},
    %{host: "10.10.10.28", port: 2113},
    %{host: "10.10.10.30", port: 2113}
  ],
  connection_name: :my_app,
  username: "admin",
  password: "changeit"
```

* `gossip_timeout` - in ms. Defaults to 1_000. We are iterating through `nodes` list, asking for cluster member details.
This setting represents timeout for gossip response before we are asking next node from `nodes` list for cluster details.
* `nodes` - Mandatory for cluster connection. Represents list of nodes in the cluster as we know it
  * `host` - should be EXT IP setting of your EventStore node
  * `port` - should be EXT HTTP PORT setting of your EventStore node
* `mode` - Defaults to `:write` where Master node is prefered over Slave, otherwise prefer Slave over Master

Example of connection to cluster via DNS lookup

```elixir
config :extreme, :event_store,
 db_type: :cluster_dns,
 gossip_timeout: 300,
 host: "es-cluster.example.com", # accepts char list too, this whould be multy A record host enrty in your nameserver
 port: 2113, # the external gossip port
 connection_name: :my_app,
 username: "admin",
 password: "changeit",
 mode: :write,
 max_attempts: :infinity
```

When `cluster` mode is used, adapter goes thru `nodes` list and tries to gossip with node one after another
until it gets response about nodes. Based on nodes information from that response it ranks their statuses and chooses
the best candidate to connect to. For `:write` mode (default) `Master` node is prefered over `Slave`,
but for `:read` mode it is opposite. For the way ranking is done, take a look at `lib/cluster_connection.ex`:

```elixir
defp rank_state("Master", :write),    do: 1
defp rank_state("Master", _),         do: 2
defp rank_state("PreMaster", :write), do: 2
defp rank_state("PreMaster", _),      do: 3
defp rank_state("Slave", :write),     do: 3
defp rank_state("Slave", _),          do: 1
```

Note that above will work with same procedure with `cluster_dns` mode turned on, since internally it will get ip addresses to which the same connection procedure will be used.

Once client is disconnected from EventStore, supervisor should respawn it and connection starts over again.

### Read-only clients

Extreme modules may be configured as read-only with the `:read_only` option
(default: `false`)

```elixir
config :extreme, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  reconnect_delay: 2_000,
  connection_name: :my_app,
  max_attempts: :infinity,
  read_only: true # <- marked as read-only
```

Read-only modules are not allowed to perform write operations like writing
events or deleting streams. Read-only clients may execute the following
messages:

- `ReadEvent`
- `ReadStreamEvents`
- `ReadStreamEventsBackward`
- `ReadAllEvents`
- `ConnectToPersistentSubscription`
- `SubscribeToStream`
- `UnsubscribeFromStream`

Use read-only clients to ensure that a listener does not commit writes. This is
particularly useful for Read Models.

### Communication

EventStore uses ProtoBuf for taking requests and sending responses back.
We are using [exprotobuf](https://github.com/bitwalker/exprotobuf) to deal with them.
List and specification of supported protobuf messages can be found in `include/event_store.proto` file.

Instead of wrapping each and every request in elixir function, we are using `execute/2` function that takes server pid and request message:

```elixir
{:ok, response} = Extreme.execute server, write_events()
```

where `write_events` can be helper function like:

```elixir
alias Extreme.Msg, as: ExMsg

defp write_events(stream \\ "people", events \\ [%PersonCreated{name: "Pera Peric"}, %PersonChangedName{name: "Zika"}]) do
  proto_events = Enum.map(events, fn event ->
    ExMsg.NewEvent.new(
      event_id: Extreme.Tools.gen_uuid(),
      event_type: to_string(event.__struct__),
      data_content_type: 0,
      metadata_content_type: 0,
      data: :erlang.term_to_binary(event),
      metadata: ""
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


`Extreme.read_and_stay_subscribed/7` reads all events that follow a specified event number, and subscribes to future events.

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
  def handle_info(:caught_up, state) do
    Logger.debug "We are up to date!"
    {:noreply, state}
  end
  def handle_info(_msg, state), do: {:noreply, state}

  defp process_event(event), do: IO.puts("Do something with #{inspect event}")
  defp update_last_event(_stream, _event_number), do: IO.puts("Persist last processed event_number for stream")
end
```

This way unprocessed events will be sent by Extreme, using `{:on_event, push}` message.
After all persisted messages are sent, :caught_up message is sent and then new messages will be sent the same way
as they arrive to stream.

If you subscribe to non existing stream you'll receive message {:extreme, severity, problem, stream} where severity can be either `:error` (for subscription on hard deleted stream) or `:warn` (for subscription on non existing or soft deleted stream). Problem is explanation of problem (i.e. :stream_hard_deleted). So in your receiver you can either have catch all `handle_info(_message, _state)` or you can handle such message:

```elixir
def handle_info({:extreme, _, problem, stream}=message, state) do
  Logger.warn "Stream #{stream} issue: #{to_string problem}"
  {:noreply, state}
end
```

### Extreme.Listener

Since it is common on read side of system to read events and denormalize them,
there is Extreme.Listener macro that hides noise from listener:

```elixir
defmodule MyApp.MyListener do
  use Extreme.Listener
  import MyApp.MyProcessor

  # returns last processed event by MyListener on stream_name, -1 if none has been processed so far
  defp get_last_event(stream_name), do: DB.get_last_event MyListener, stream_name

  defp process_push(push, stream_name) do
    #for indexed stream we need to follow push.link.event_number, otherwise push.event.event_number
    event_number = push.link.event_number
    DB.in_transaction fn ->
      Logger.info "Do some processing of event #{inspect push.event.event_type}"
      :ok = push.event.data
             |> :erlang.binary_to_term
             |> process_event(push.event.event_type)
      DB.ack_event(MyListener, stream_name, event_number)
    end
    {:ok, event_number}
  end

  # This override is optional
  defp caught_up, do: Logger.debug("We are up to date. YEEEY!!!")
end

defmodule MyApp.MyProcessor do
  def process_event(data, "Elixir.MyApp.Events.PersonCreated") do
    Logger.debug "Doing something with #{inspect data}"
    :ok
  end
  def process_event(_, _), do: :ok # Just acknowledge events we are not interested in
end
```

Listener can be started manually but it is most common to place it in supervisor AFTER specifing Extreme:

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link, do: Supervisor.start_link __MODULE__, :ok

  @event_store MyApp.EventStore

  def init(:ok) do
    event_store_settings = Application.get_env :my_app, :event_store

    children = [
      worker(Extreme, [event_store_settings, [name: @event_store]]),
      worker(MyApp.MyListener, [@event_store, "my_indexed_stream", [name: MyListener]]),
      # ... other workers / supervisors
    ]
    supervise children, strategy: :one_for_one
  end
end
```

Subscription can be paused:

```elixir
{:ok, last_event_number} = MyApp.MyListener.pause MyListener
```

and resumed

```elixir
:ok = MyApp.MyListener.resume MyListener
```

### Extreme.FanoutListener

It's not uncommon situation to listen live events and propagate them (for example on web sockets).
For that situation there is Extreme.FanoutListener macro that hides noise from listener:

```elixir
defmodule MyApp.MyFanoutListener do
  use Extreme.FanoutListener
  import MyApp.MyPusher

  defp process_push(push) do
    Logger.info "Forward to web socket event #{inspect push.event.event_type}"
    :ok = push.event.data
           |> :erlang.binary_to_term
           |> process_event(push.event.event_type)
  end
end

defmodule MyApp.MyPusher do
  def process_event(data, "Elixir.MyApp.Events.PersonCreated") do
    Logger.debug "Transform and push event with data: #{inspect data}"
    :ok
  end
  def process_event(_, _), do: :ok # Just acknowledge events we are not interested in
end
```

Listener can be started manually but it is most common to place it in supervisor AFTER specifing Extreme:

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link, do: Supervisor.start_link __MODULE__, :ok

  @event_store MyApp.EventStore

  def init(:ok) do
    event_store_settings = Application.get_env :my_app, :event_store

    children = [
      worker(Extreme, [event_store_settings, [name: @event_store]]),
      worker(MyApp.MyFanoutListener, [@event_store, "my_indexed_stream", [name: MyFanoutListener]]),
      # ... other workers / supervisors
    ]
    supervise children, strategy: :one_for_one
  end
end
```

### Persistent subscriptions

The Event Store provides an alternate event subscription model, from version 3.2.0, known as [competing consumers](http://docs.geteventstore.com/introduction/latest/competing-consumers). Instead of the client holding the state of the subscription, the server remembers it.

#### Create a persistent subscription

The first step in using persistent subscriptions is to create a new subscription. This can be done using the Event Store admin website or in your application code, as shown below.  You must provide a unique subscription group name and the stream to receive events from.

```elixir
alias Extreme.Msg, as: ExMsg

{:ok, _} = Extreme.execute(server, ExMsg.CreatePersistentSubscription.new(
  subscription_group_name: "person-subscription",
  event_stream_id: "people",
  resolve_link_tos: false,
  start_from: 0,
  message_timeout_milliseconds: 10_000,
  record_statistics: false,
  live_buffer_size: 500,
  read_batch_size: 20,
  buffer_size: 500,
  max_retry_count: 10,
  prefer_round_robin: true,
  checkpoint_after_time: 1_000,
  checkpoint_max_count: 500,
  checkpoint_min_count: 1,
  subscriber_max_count: 1
))
```

#### Connect to a persistent subscription

`Extreme.connect_to_persistent_subscription/5` function is used subscribe to an existing persistent subscription. The subscriber, in this example `self`, will receive message `{:on_event, push_message}` when each new event is added to stream
_people_.

```elixir
{:ok, subscription} = Extreme.connect_to_persistent_subscription(server, self(), group, stream, buffer_size)
```

#### Receive & acknowledge events

You must acknowledge receipt, and successful processing, of each received event. The Event Store will remember the last acknowledged event. The subscription will resume from this position should the subscriber process terminate and reconnect. This simplifies the client logic - the code you must write.

`Extreme.PersistentSubscription.ack/3` function is used to acknowledge receipt of an event.

```elixir
receive do
  {:on_event, event, correlation_id} ->
    Logger.debug "New event added to stream 'people': #{inspect event}"
    :ok = Extreme.PersistentSubscription.ack(subscription, event, correlation_id)
end
```

You must track the `subscription` PID returned from the `Extreme.connect_to_persistent_subscription/5` function as part of the process state when using a `GenServer` subscriber.

```elixir
def handle_info({:on_event, event, correlation_id}, %{subscription: subscription} = state) do
  Logger.debug "New event added to stream 'people': #{inspect event}"
  :ok = Extreme.PersistentSubscription.ack(subscription, event, correlation_id)
  {:noreply, state}
end
```

Events can also be not acknowledged. They can be not acknowledged with a nack_action of :Park, :Retry, :Skip, or :Stop.

```elixir
def handle_info({:on_event, event, correlation_id}, %{subscription: subscription} = state) do
  Logger.debug "New event added to stream 'people': #{inspect event}"
  if needs_to_retry do
    :ok = Extreme.PersistentSubscription.nack(subscription, event, correlation_id, :Retry)
  else
    :ok = Extreme.PersistentSubscription.ack(subscription, event, correlation_id)
  end
  {:noreply, state}
end
```

## Building modules from .proto file

Follow steps 1. and 2. from https://github.com/tony612/protobuf-elixir#generate-elixir-code,
then run:

```bash
protoc --elixir_out=./ include/event_store.proto && \
sed -i '' 's/EventStore\.Client/Extreme/g' include/event_store.pb.ex && \
mv include/event_store.pb.ex lib/extreme/messages.ex
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Licensed under The MIT License.

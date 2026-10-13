# v1.2.0

This minor release contains breaking changes; Extreme makes breaking changes in minor versions.

## Breaking changes

- Requires Elixir 1.16 or later.
- `elixir_uuid` is no longer a dependency. If your project calls `UUID`, directly or through a library that only has it as an optional dependency, add `{:elixir_uuid, "~> 1.2"}` to your deps. With x3m_system 0.9.7 or earlier, add `elixir_uuid` yourself or upgrade to x3m_system 0.10.0.
- If your dialyzer PLT lists apps explicitly (`plt_add_deps: :apps_direct` or a fixed `plt_add_apps`), add `:protobuf` to it: Extreme's message types reference `t:Protobuf.unknown_field/0`.
- An unset `event` in `ResolvedIndexedEvent`, `ResolvedEvent`, `ReadEventCompleted`, `StreamEventAppeared` and `PersistentSubscriptionStreamEventAppeared` (e.g. a resolved link whose event was deleted) now decodes as `nil`, not as a struct with all fields `nil`. Add a `%{event: nil}` clause before any clause that binds `event` and reads its fields.
- exprotobuf-only functions are gone from `Extreme.Messages.*`: `encode_delimited/1`, `decode_delimited/1`, `defs/0,2,3`, `record/0` and `syntax/0` on messages, and `atom/1`, `atoms/0` and `values/0` on enums. Use `encode/1` and `decode/1` (add or strip the varint length prefix yourself where you used the `*_delimited` forms), `key/1` instead of `atom/1`, and `mapping/0` instead of `atoms/0` and `values/0`; `value/1` is unchanged.
- String and bytes fields of `Extreme.Messages.*` must be binaries; only `NewEvent` `data` and `metadata` still take iodata. Pass binaries, e.g. `IO.iodata_to_binary/1`.
- `Extreme.Messages.*` structs have two more keys, `__unknown_fields__` and `__protobuf__`, which `Map.from_struct/1` includes. Drop them before comparing or serializing such maps: `Map.drop(map, [:__unknown_fields__, :__protobuf__])`.
- `execute` and `ping` with a message that cannot be encoded return `{:error, {:encoding_failed, reason}}` (`reason` is a `Protobuf.EncodeError`) instead of timing out, and `connect_to_persistent_subscription` with an invalid stream or group returns `{:error, reason}` instead of failing silently. Add a clause if you match on their results.
- A persistent subscription whose ack or nack cannot be encoded now stops, and its subscriber gets `{:extreme, {:encoding_failed, reason}}`, as it also does when connecting cannot be encoded. Handle that message in your subscriber.

## Change

- `exprotobuf` is replaced by `protobuf` 0.17. The wire format, the `Extreme.Messages.*` module names, fields and enum values, and `new/0,1` stay the same; the breaking changes above list what differs.
- No more compile or runtime deprecation warnings from the message modules.
- Generated correlation and event ids are UUIDv7 (time-ordered).

## Fix

- A request whose caller timed out waiting for EventStoreDB is no longer kept forever.
- `use Extreme.Listener` no longer warns on Elixir 1.20 when `process_push` never returns `:stop`.

# v1.1.5

## Fix

- `read_and_stay_subscribed` (and `Extreme.Listener`) no longer crashes when starting beyond the stream's end.
- `read_and_stay_subscribed` now rejects `per_page` 0 and a negative `from_event_number` at the call.
- `read_and_stay_subscribed` on a just-recreated soft-deleted stream no longer skips its existing events.

# v1.1.4

## Fix?

- removed specs from `Extreme.Reading` functions, until they are properly fixed.

# v1.1.3

## (Breaking) change

- call for subscribe in `Extreme.Listener` will be ignored if there's live subscription,
  avoiding double subscriptions that result in doubled push messages for the same new live events.

# v1.1.2

## New

- Add Extreme.set/get_metadata
- Add Extreme.scavenge_database
- Add Extreme.read_events/3 and Extreme.read_events_backwards/3

# v1.1.1

## Breaking changes

- `ListenerWithBackPressure.on_init/1` doesn't support `:ok` result anymore, it must return `{:ok, client_state}`

## New

- add `on_caught_up(client_state)` callback to ListenerWithBackPressure

## Improvements

- Stop sending already read events to subscriber, if it returned `:stop` from processing previous one.

# v1.1.0

## Breaking changes

- Rename `RequestManager._unregister_subscription/2` (removed leading `_`)

## New

- Add event_producer functionality for module that uses `Extreme`.
- Add option to exclude catch all `handle_info` when using `Extreme.Listener`

# v1.0.7

- Fix stoping subscription if `on_event` callback returns `:stop`

# v1.0.6

- Add `Listener.subscribed?/1` function

# v1.0.5

- RequestManager buffers live events received after subscription is created,
  but before it is registered

# v1.0.4

- Listener.process_push callback can return `:stop`, meaning subscription should be stopped
  and pushes that are already in mailbox should be purged.

# v1.0.3

- Add subscribe/unsubscribe and auto_subscribe? option for starting `Extreme.Listener`

# v1.0.0-beta2

- Restart all subscriptions and subscribers/listeners when connection receives :tcp_closed

# v0.13.1

- Dependency version upgrades

# v0.13.0

- Support Elixir 1.7.0 and OTP 21.0
- Listener reads events in chunks of 500 events (instead of 4096)

# v0.11.0

- Added support for EventStore 4

# v0.10.4

- Fixed issue with concurrent read and write where messages get stuck into extreme process state

# v0.10.3

- Extreme.Listener - if get_last_event/1 returns `:from_now`, catching events will start from current event

# Changelog for Extreme v0.10.2

- Fix end of patching in Listener

# Changelog for Extreme v0.10.1

- Dependecy upgrades
- Tested with Elixir 1.5.2 and OTP 20.1

# Changelog for Extreme v0.9.2

- Added support for nacking messages from persistent connections (thanks to [@nathanfox](https://github.com/nathanfox))

# Changelog for Extreme v0.9.1

- Support persistent subscriptions on projection streams (e.g. `$ce-category`)

# Changelog for Extreme v0.9.0

- Added support for persistent connections (thanks to [@slashdotdash](https://github.com/slashdotdash))
- BREAKING CHANGE: Module `Extreme.Messages` is renamed to `Extreme.Msg`

# Changelog for Extreme v0.8.1

- Added pause, resume and patch functionalities for Extreme.Listener

# Changelog for Extreme v0.8.0

- Tested with Elixir 1.4.0 with fixed warnings
- Listener won't crash if ES is down. It will try to reconnect each 1sec instead of immediately
- Extreme.Listener.caught_up/0 callback is public now
- Bumped up all dependency versions

# Changelog for Extreme v0.7.1

- When connecting to ES cluster choose mode :write (default) to prefer Master over Slave or :read for opposite

# Changelog for Extreme v0.7.0

- When read_and_stay_subscribed/7 function is called, :caught_up message is sent to subscriber after existing events
  are read (or if there were no events) and before new events arrive. This is sign to your listener that you are
  up-to-date. If you don't have catch all handle_info/2 in your receiver this is breaking change!

# Changelog for Extreme v0.6.2

- Added Extreme.FanoutListener
- Added inline documentation

# Changelog for Extreme v0.6.1

- Removed PersistentSubscription related proto messages since when compiled
  they generate files longer then 100 characters and as such release can't be built

# Changelog for Extreme v0.6.0

- Added Extreme.Listener

# Changelog for Extreme v0.5.5

- Removed PersistentSubscription related proto messages since when compiled
  they generate files longer then 100 characters and as such release can't be built

# Changelog for Extreme v0.5.4

- Read events backward (see example in test file)
- Some code cleanup and proto file updated (thanks to @mindreframer)
- Tested with Elixir 1.3.2 and EventStore 3.9.0

# Changelog for Extreme v0.5.3

- Tested with Elixir 1.3.2 and EventStore 3.6.2

# Changelog for Extreme v0.5.2

- Minor improvements
- Upgraded depencey versions
- Tested with Elixir 1.3.0 and EventStore 3.6.2

# Changelog for Extreme v0.5.1

- Stop Extreme process when tcp is closed by EventStore
- Adding Dns cluster connection support for configuration
- Tested with Elixir 1.2.5 and EventStore 3.5.0

# Changelog for Extreme v0.5.0

- You can subscribe to non-existing stream now with subscribe_to/4 and read_and_stay_subscribed/7 functions. If you do such thing however, you'll be sent message {:extreme, severity, problem, stream}. If you don't have catch all handle_info/2 in your receiver this is breaking change.
- More tests added
- Tested with Elixir 1.2.3 and EventStore 3.4.0

# Changelog for extreme v0.13.4
  * Allow running on all Elixir versions > 1.0

# Changelog for extreme v0.13.3
  * Fixing read_all_events forward and backward
  * simple benchmark app to test write speed

# Changelog for extreme v0.13.2
  * Listener accepts `:read_per_page` option in `start_link/3` which defaults to 500

# Changelog for extreme v0.13.1
  * Dependency version upgrades

# Changelog for extreme v0.13.0
  * Support Elixir 1.7.0 and OTP 21.0
  * Listener reads events in chunks of 500 events (instead of 4096)
  
# Changelog for extreme v0.11.0
  * Added support for EventStore 4
  
# Changelog for extreme v0.10.4
  * Fixed issue with concurrent read and write where messages get stuck into extreme process state
  
# Changelog for extreme v0.10.3
  * Extreme.Listener - if get_last_event/1 returns `:from_now`, catching events will start from current event

# Changelog for Extreme v0.10.2
  * Fix end of patching in Listener

# Changelog for Extreme v0.10.1
  * Dependecy upgrades
  * Tested with Elixir 1.5.2 and OTP 20.1

# Changelog for Extreme v0.9.2
  * Added support for nacking messages from persistent connections (thanks to [@nathanfox](https://github.com/nathanfox))

# Changelog for Extreme v0.9.1
  * Support persistent subscriptions on projection streams (e.g. `$ce-category`)

# Changelog for Extreme v0.9.0
  * Added support for persistent connections (thanks to [@slashdotdash](https://github.com/slashdotdash))
  * BREAKING CHANGE: Module `Extreme.Messages` is renamed to `Extreme.Msg`

# Changelog for Extreme v0.8.1
  * Added pause, resume and patch functionalities for Extreme.Listener

# Changelog for Extreme v0.8.0
  * Tested with Elixir 1.4.0 with fixed warnings
  * Listener won't crash if ES is down. It will try to reconnect each 1sec instead of immediately
  * Extreme.Listener.caught_up/0 callback is public now
  * Bumped up all dependency versions

# Changelog for Extreme v0.7.1
  * When connecting to ES cluster choose mode :write (default) to prefer Master over Slave or :read for opposite

# Changelog for Extreme v0.7.0
  * When read_and_stay_subscribed/7 function is called, :caught_up message is sent to subscriber after existing events
    are read (or if there were no events) and before new events arrive. This is sign to your listener that you are
    up-to-date. If you don't have catch all handle_info/2 in your receiver this is breaking change!

# Changelog for Extreme v0.6.2
  * Added Extreme.FanoutListener
  * Added inline documentation

# Changelog for Extreme v0.6.1
  * Removed PersistentSubscription related proto messages since when compiled
    they generate files longer then 100 characters and as such release can't be built

# Changelog for Extreme v0.6.0
  * Added Extreme.Listener

# Changelog for Extreme v0.5.5
  * Removed PersistentSubscription related proto messages since when compiled
    they generate files longer then 100 characters and as such release can't be built

# Changelog for Extreme v0.5.4
  * Read events backward (see example in test file)
  * Some code cleanup and proto file updated (thanks to @mindreframer)
  * Tested with Elixir 1.3.2 and EventStore 3.9.0

# Changelog for Extreme v0.5.3
  * Tested with Elixir 1.3.2 and EventStore 3.6.2


# Changelog for Extreme v0.5.2
  * Minor improvements
  * Upgraded depencey versions
  * Tested with Elixir 1.3.0 and EventStore 3.6.2


# Changelog for Extreme v0.5.1

  * Stop Extreme process when tcp is closed by EventStore
  * Adding Dns cluster connection support for configuration
  * Tested with Elixir 1.2.5 and EventStore 3.5.0


# Changelog for Extreme v0.5.0

  * You can subscribe to non-existing stream now with subscribe_to/4 and read_and_stay_subscribed/7 functions. If you do such thing however, you'll be sent message {:extreme, severity, problem, stream}. If you don't have catch all handle_info/2 in your receiver this is breaking change.
  * More tests added
  * Tested with Elixir 1.2.3 and EventStore 3.4.0

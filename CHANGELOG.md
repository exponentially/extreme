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

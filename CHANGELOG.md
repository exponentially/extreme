# Changelog for Extreme v0.5.0

  * You can subscribe to non-existing stream now with subscribe_to/4 and read_and_stay_subscribed/7 functions. If you do such thing however, you'll be sent message {:extreme, severity, problem, stream}. If you don't have catch all handle_info/2 in your receiver this is breaking change.
  * More tests added
  * Tested with Elixir 1.2.3 and EventStore 3.4.0

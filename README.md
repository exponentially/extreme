Extreme
=======

EventStore Erlang/Elixir TCP client

Driver supports:

* Write event(s) to regular stream.
* Authenticated communication with EventStore server. (Partial... driver is still in prototype phase)


TODO
====

* Authenticated communication with EventStore server. (Full support)
* Read event(s) from regular or $all stream (forward or backward).
* Read stream metadata (ACL and custom properties).
* Write stream metadata (ACL and custom properties).
* Delete regular stream.
* Transactional writes to regular stream.
* Volatile subscriptions to regular or $all stream.
* Catch-up subscriptions to regular or $all stream.
* Competing consumers (a.k.a Persistent subscriptions) to regular stream.

Dependencies
============

* exprotobuf ~> 0.10.2
* uuid ~> 1.0
* poison ~> 1.4.0


Licensed under The MIT License.
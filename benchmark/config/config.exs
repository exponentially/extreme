# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :benchmark, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:benchmark, :key)
#
# You can also configure a 3rd-party app:
#
config :logger, level: :debug
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :extreme, :protocol_version, 4

config :benchmark, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  reconnect_delay: 2_000,
  mode: :write,
  connection_name: :extreme_test,
  max_attempts: :infinity

# config :benchmark, :event_store,
#   db_type: :cluster,
#   gossip_timeout: 300,
#   nodes: [
#     %{host: "192.168.192.100", port: 2111},
#     %{host: "192.168.192.100", port: 2112},
#     %{host: "192.168.192.100", port: 2113}
#   ],
#   username: "admin",
#   password: "changeit",
#   # default is :infinity
#   max_attempts: :infinity,
#   connection_name: :extreme_test

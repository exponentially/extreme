use Mix.Config

# EventStore
config :extreme, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  # in ms. Defaults to 1_000
  reconnect_delay: 2_000,
  mode: :write,
  connection_name: :extreme_test,
  max_attempts: :infinity

config :extreme, :protocol_version, System.get_env("ES_VERSION") || 3

## settings for cluster
# config :extreme, :event_store,
#  db_type: :cluster, #default is :node
#  gossip_timeout: 300, #in ms. Defaults to 1_000
#  nodes: [
#    %{host: "10.10.10.29", port: 2113},
#    %{host: "10.10.10.28", port: 2113},
#    %{host: "10.10.10.30", port: 2113}
#  ],
#  username: "admin",
#  password: "changeit",
#  max_attempts: :infinity #default is :infinity

## settings for cluster discover via DNS
# config :extreme, :event_store,
#  db_type: :cluster_dns, #default is :node
#  gossip_timeout: 300, #in ms. Defaults to 1_000
#  host: "www.google.com",
#  port: 2113,
#  username: "admin",
#  password: "changeit",
#  max_attempts: :infinity #default is :infinity

config :logger, :console,
  level: :debug,
  format: "$time [$level] $metadata$message\n",
  metadata: [:user_id]

config :ex_unit,
  assert_receive_timeout: 2_000,
  capture_log: true

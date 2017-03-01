use Mix.Config

# EventStore
config :extreme, :event_store,
  db_type:         :node, 
  host:            "localhost", 
  port:            1113, 
  username:        "admin", 
  password:        "changeit",
  reconnect_delay: 2_000, #in ms. Defaults to 1_000
  mode:            :write,
  max_attempts:    :infinity

## settings for cluster
#config :extreme, :event_store,
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
  level:    :debug,
  format:   "$time [$level] $metadata$message\n",
  metadata: [:user_id]


use Mix.Config

# EventStore
config :extreme, :event_store,
  db_type: :node, 
  host: "localhost", 
  port: 1113, 
  username: "admin", 
  password: "changeit",
  reconnect_delay: 2,
  max_attempts: :infinity
#config :extreme, :event_store,
#  db_type: :cluster, 
#  nodes: [
#    %{host: "10.10.10.29", port: 2113},
#    %{host: "10.10.10.28", port: 2113},
#    %{host: "10.10.10.30", port: 2113}
#  ],
#  username: "admin", 
#  password: "changeit",
#  max_attempts: :infinity

config :logger, :console,
  level: :debug,
  format: "$time [$level] $metadata$message\n",
  metadata: [:user_id]


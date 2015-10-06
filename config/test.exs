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

config :logger, :console,
  level: :debug,
  format: "$time [$level] $metadata$message\n",
  metadata: [:user_id]


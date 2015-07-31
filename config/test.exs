use Mix.Config

# EventStore
config :event_store,
  db_type: :node, 
  host: "localhost", 
  port: 1113, 
  username: "admin", 
  password: "changeit"

config :logger, :console,
  level: :debug,
  format: "$time [$level] $metadata$message\n",
  metadata: [:user_id]


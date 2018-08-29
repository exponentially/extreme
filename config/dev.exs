use Mix.Config

config :logger, :console,
  level: :debug,
  format: "$time [$level] $message\n"

config :extreme, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit"

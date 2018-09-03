use Mix.Config

config :logger, :console,
  level: :debug,
  format: "$time [$level] $message\n"

config :ex_unit,
  capture_log: true

config :extreme, TestConn,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  connection_name: "extreme_test"

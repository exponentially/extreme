use Mix.Config

config :logger, :console,
  level: :debug,
  format: "$time [$level] $message\n"

config :ex_unit,
  capture_log: true

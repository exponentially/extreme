use Mix.Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:pid, :module, :function]

config :ex_unit,
  assert_receive_timeout: 10_000,
  capture_log: true

transport_opts =
  if cacertfile = System.get_env("EXTREME_CACERTFILE") do
    [
      transport: :ssl,
      transport_opts: [
        verify: :verify_peer,
        cacertfile: cacertfile
      ]
    ]
  else
    []
  end

config :extreme,
       TestConn,
       [
         db_type: "node",
         host: "localhost",
         port: "1113",
         username: "admin",
         password: "changeit",
         connection_name: "extreme_test"
       ] ++ transport_opts

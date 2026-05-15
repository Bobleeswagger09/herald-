import Config

config :herald, Herald.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "herald_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :herald, HeraldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_64_characters_long_for_testing_only!",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :swoosh, :api_client, false

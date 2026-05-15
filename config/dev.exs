import Config

config :herald, Herald.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "herald_dev",
  pool_size: 10,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :herald, HeraldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_at_least_64_chars_long_replace_in_prod_!!",
  watchers: []

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]

config :swoosh, :api_client, false

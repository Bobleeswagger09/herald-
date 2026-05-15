import Config

config :herald,
  ecto_repos: [Herald.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :herald, HeraldWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: HeraldWeb.ErrorJSON], layout: false],
  pubsub_server: Herald.PubSub,
  live_view: [signing_salt: "change_me_in_prod"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"

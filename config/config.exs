import Config

config :notification_service,
  ecto_repos: [NotificationService.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :notification_service, NotificationService.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: NotificationService.ErrorJSON], layout: false],
  pubsub_server: NotificationService.PubSub,
  live_view: [signing_salt: "change_me_in_prod"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
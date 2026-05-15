defmodule NotificationService.Endpoint do
  use Phoenix.Endpoint, otp_app: :notification_service

  socket "/socket", NotificationService.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug NotificationService.Router
end

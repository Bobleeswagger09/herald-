defmodule NotificationService.Router do
  use Phoenix.Router
  import Plug.Conn

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", NotificationService do
    pipe_through :api

    post "/notifications", NotificationController, :create
    get "/notifications", NotificationController, :index
    post "/notifications/:id/requeue", NotificationController, :requeue
  end

  get "/healthz", Herald.HealthController, :healthz
  get "/readyz", Herald.HealthController, :readyz
end

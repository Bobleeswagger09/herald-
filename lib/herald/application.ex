defmodule NotificationService.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NotificationService.Repo,
      NotificationService.DBListener,
      {Phoenix.PubSub, name: NotificationService.PubSub},
      {DynamicSupervisor,
       name: NotificationService.SessionSupervisor, strategy: :one_for_one},
      NotificationService.Telemetry,
      NotificationService.Endpoint
    ]

    opts = [strategy: :one_for_one, name: NotificationService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    NotificationService.Endpoint.config_change(changed, removed)
    :ok
  end
end
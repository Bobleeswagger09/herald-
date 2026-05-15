defmodule Herald.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Herald.Repo,
      Herald.DBListener,
      {Phoenix.PubSub, name: Herald.PubSub},
      {DynamicSupervisor, name: Herald.SessionSupervisor, strategy: :one_for_one},
      HeraldWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Herald.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HeraldWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

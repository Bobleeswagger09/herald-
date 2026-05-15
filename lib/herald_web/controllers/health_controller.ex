defmodule Herald.HealthController do
  use Phoenix.Controller, formats: [:json]

  def healthz(conn, _params) do
    json(conn, %{status: "ok"})
  end

  def readyz(conn, _params) do
    case Herald.Repo.query("SELECT 1") do
      {:ok, _} -> json(conn, %{status: "ok", db: "connected"})
      {:error, _} -> conn |> put_status(503) |> json(%{status: "error", db: "disconnected"})
    end
  end
end

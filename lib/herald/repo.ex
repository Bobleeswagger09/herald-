defmodule Herald.Repo do
  use Ecto.Repo,
    otp_app: :herald,
    adapter: Ecto.Adapters.Postgres
end

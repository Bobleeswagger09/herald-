defmodule NotificationService.NotificationController do
  use Phoenix.Controller, formats: [:json]

  alias NotificationService.Notifications

  def create(conn, params) do
    attrs = %{
      user_id: params["user_id"],
      type:    params["type"],
      title:   params["title"],
      body:    params["body"],
      payload: params["payload"] || %{}
    }

    case Notifications.create_notification(attrs) do
      {:ok, notification} ->
        conn |> put_status(:created) |> json(%{data: encode(notification)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def index(conn, %{"user_id" => user_id} = params) do
    limit = Map.get(params, "limit", "100") |> String.to_integer()
    notifications = Notifications.list_for_user(user_id, limit: limit)
    json(conn, %{data: Enum.map(notifications, &encode/1)})
  end

  def requeue(conn, %{"id" => id}) do
    notification = Notifications.get_notification!(id)

    case Notifications.requeue(notification) do
      {:ok, updated} -> json(conn, %{data: encode(updated)})
      {:error, cs}   -> conn |> put_status(422) |> json(%{errors: format_errors(cs)})
    end
  end

  defp encode(n) do
    %{
      id:          n.id,
      user_id:     n.user_id,
      type:        n.type,
      title:       n.title,
      body:        n.body,
      payload:     n.payload,
      status:      n.status,
      retry_count: n.retry_count,
      inserted_at: DateTime.to_iso8601(n.inserted_at)
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
  end
end
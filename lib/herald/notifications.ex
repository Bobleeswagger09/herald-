defmodule NotificationService.Notifications do
  import Ecto.Query

  alias NotificationService.Repo
  alias NotificationService.Notifications.Notification

  def get_notification!(id), do: Repo.get!(Notification, id)

  def list_pending(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Notification
    |> where([n], n.user_id == ^user_id and n.status == "pending")
    |> order_by([n], asc: n.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    Notification
    |> where([n], n.user_id == ^user_id)
    |> order_by([n], desc: n.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def mark_delivered(%Notification{} = notification) do
    notification |> Notification.deliver_changeset() |> Repo.update()
  end

  def mark_failed(%Notification{} = notification) do
    notification |> Notification.fail_changeset() |> Repo.update()
  end

  def requeue(%Notification{} = notification) do
    notification
    |> Ecto.Changeset.change(status: "pending", retry_count: 0)
    |> Repo.update()
  end
end

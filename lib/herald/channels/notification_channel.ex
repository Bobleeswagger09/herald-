defmodule NotificationService.Channels.NotificationChannel do
  use Phoenix.Channel
  require Logger

  alias NotificationService.{Notifications, Workers.UserSession}

  def join("notifications:" <> user_id, _params, socket) do
    if socket.assigns[:user_id] == user_id do
      send(self(), {:after_join, user_id})
      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_, _, _), do: {:error, %{reason: "invalid_topic"}}

  def handle_info({:after_join, user_id}, socket) do
    case UserSession.find(user_id) do
      nil ->
        {:ok, _} =
          DynamicSupervisor.start_child(
            NotificationService.SessionSupervisor,
            {UserSession, %{user_id: user_id, channel_pid: self()}}
          )

      _pid ->
        UserSession.register_channel(user_id, self())
    end

    pending = Notifications.list_pending(user_id)
    push(socket, "notification_list", %{notifications: encode_many(pending)})
    {:noreply, socket}
  end

  def handle_info({:push_notification, notification}, socket) do
    push(socket, "new_notification", encode(notification))
    {:noreply, socket}
  end

  def handle_in("ack", %{"notification_id" => id}, socket) do
    UserSession.ack(socket.assigns.user_id, id)
    {:reply, :ok, socket}
  end

  def handle_in("list", params, socket) do
    limit = Map.get(params, "limit", 50)
    notifications = Notifications.list_pending(socket.assigns.user_id, limit: limit)
    {:reply, {:ok, %{notifications: encode_many(notifications)}}, socket}
  end

  def handle_in(event, _params, socket) do
    Logger.warning("[NotificationChannel] Unknown event: #{event}")
    {:reply, {:error, %{reason: "unknown_event"}}, socket}
  end

  def terminate(_reason, _socket), do: :ok

  defp encode(n) do
    %{
      id: n.id,
      type: n.type,
      title: n.title,
      body: n.body,
      payload: n.payload,
      status: n.status,
      inserted_at: DateTime.to_iso8601(n.inserted_at)
    }
  end

  defp encode_many(notifications), do: Enum.map(notifications, &encode/1)
end

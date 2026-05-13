defmodule NotificationService.NotificationsTest do
  use NotificationService.DataCase, async: true

  alias NotificationService.Notifications
  alias NotificationService.Notifications.Notification

  @user_id "550e8400-e29b-41d4-a716-446655440000"

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(%{user_id: @user_id, type: "message", title: "Test", body: "Hello"}, overrides)
  end

  test "creates with valid attrs" do
    assert {:ok, %Notification{status: "pending"}} =
             Notifications.create_notification(valid_attrs())
  end

  test "fails without user_id" do
    assert {:error, changeset} =
             Notifications.create_notification(%{type: "message", title: "Hi"})
    assert %{user_id: ["can't be blank"]} = errors_on(changeset)
  end

  test "mark_delivered sets status and timestamp" do
    {:ok, n} = Notifications.create_notification(valid_attrs())
    {:ok, updated} = Notifications.mark_delivered(n)
    assert updated.status == "delivered"
    assert updated.delivered_at != nil
  end

  test "mark_failed increments retry_count" do
    {:ok, n} = Notifications.create_notification(valid_attrs())
    {:ok, failed} = Notifications.mark_failed(n)
    assert failed.status == "failed"
    assert failed.retry_count == 1
  end

  test "requeue resets status and retry_count" do
    {:ok, n} = Notifications.create_notification(valid_attrs())
    {:ok, failed} = Notifications.mark_failed(n)
    {:ok, requeued} = Notifications.requeue(failed)
    assert requeued.status == "pending"
    assert requeued.retry_count == 0
  end

  test "list_pending returns only pending for user" do
    {:ok, n1} = Notifications.create_notification(valid_attrs(%{title: "First"}))
    {:ok, n2} = Notifications.create_notification(valid_attrs(%{title: "Second"}))
    Notifications.mark_delivered(n1)

    ids = Notifications.list_pending(@user_id) |> Enum.map(& &1.id)
    assert n2.id in ids
    refute n1.id in ids
  end
end
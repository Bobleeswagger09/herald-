defmodule NotificationService.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses ~w(pending delivered failed)
  @valid_types ~w(message alert system reminder)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :user_id,      :binary_id
    field :type,         :string
    field :title,        :string
    field :body,         :string
    field :payload,      :map,     default: %{}
    field :status,       :string,  default: "pending"
    field :retry_count,  :integer, default: 0
    field :delivered_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(notification \\ %__MODULE__{}, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :title, :body, :payload, :status])
    |> validate_required([:user_id, :type, :title])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_length(:title, max: 255)
    |> validate_length(:body, max: 2000)
  end

  def deliver_changeset(notification) do
    change(notification, status: "delivered", delivered_at: DateTime.utc_now(:second))
  end

  def fail_changeset(notification) do
    change(notification,
      status: "failed",
      retry_count: notification.retry_count + 1
    )
  end
end
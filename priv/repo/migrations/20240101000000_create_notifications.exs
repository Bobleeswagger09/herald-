defmodule NotificationService.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""

    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, :uuid, null: false
      add :type, :string, null: false, size: 50
      add :title, :string, null: false, size: 255
      add :body, :text
      add :payload, :map, default: "{}"
      add :status, :string, null: false, default: "pending", size: 20
      add :retry_count, :integer, null: false, default: 0
      add :delivered_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id, :status])
    create index(:notifications, [:status, :inserted_at])

    create constraint(:notifications, :valid_status,
             check: "status IN ('pending', 'delivered', 'failed')"
           )

    execute """
    CREATE OR REPLACE FUNCTION notify_new_notification()
    RETURNS TRIGGER AS $$
    BEGIN
      PERFORM pg_notify(
        'notifications_channel',
        jsonb_build_object('id', NEW.id, 'user_id', NEW.user_id, 'type', NEW.type)::text
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER notifications_insert_trigger
    AFTER INSERT ON notifications
    FOR EACH ROW EXECUTE FUNCTION notify_new_notification();
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS notifications_insert_trigger ON notifications"
    execute "DROP FUNCTION IF EXISTS notify_new_notification"
    drop table(:notifications)
  end
end

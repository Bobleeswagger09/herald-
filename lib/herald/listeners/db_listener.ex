defmodule NotificationService.DBListener do
  use GenServer
  require Logger

  alias NotificationService.{Notifications, PubSub}

  @pg_channel "notifications_channel"
  @reconnect_after_ms 2_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{conn: nil, ref: nil}, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    case connect() do
      {:ok, conn, ref} ->
        Logger.info("[DBListener] Listening on '#{@pg_channel}'")
        {:noreply, %{state | conn: conn, ref: ref}}

      {:error, reason} ->
        Logger.warning("[DBListener] Connect failed: #{inspect(reason)}. Retrying...")
        Process.send_after(self(), :reconnect, @reconnect_after_ms)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:notification, _pid, _ref, @pg_channel, payload}, state) do
    Task.start(fn -> process_notification(payload) end)
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{ref: ref} = state) do
    Logger.warning("[DBListener] Connection lost: #{inspect(reason)}. Reconnecting...")
    Process.send_after(self(), :reconnect, @reconnect_after_ms)
    {:noreply, %{state | conn: nil, ref: nil}}
  end

  def handle_info(:reconnect, state) do
    {:noreply, state, {:continue, :connect}}
  end

  defp connect do
    db_config = NotificationService.Repo.config()

    with {:ok, conn} <- Postgrex.Notifications.start_link(db_config),
         {:ok, ref}  <- Postgrex.Notifications.listen(conn, @pg_channel) do
      Process.monitor(conn)
      {:ok, conn, ref}
    end
  end

  defp process_notification(raw_payload) do
    with {:ok, %{"id" => id, "user_id" => user_id}} <- Jason.decode(raw_payload),
         notification when not is_nil(notification) <- safe_get(id) do
      Phoenix.PubSub.broadcast(PubSub, "user:#{user_id}", {:new_notification, notification})
    else
      {:error, reason} -> Logger.error("[DBListener] Bad payload: #{inspect(reason)}")
      nil -> Logger.warning("[DBListener] Notification not found after NOTIFY")
    end
  end

  defp safe_get(id) do
    Notifications.get_notification!(id)
  rescue
    Ecto.NoResultsError -> nil
  end
end
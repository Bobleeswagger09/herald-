defmodule NotificationService.Workers.UserSession do
  use GenServer, restart: :temporary
  require Logger

  alias NotificationService.{Notifications, PubSub}

  @max_retries 3
  @base_retry_ms 1_000

  def start_link(%{user_id: user_id} = opts) do
    GenServer.start_link(__MODULE__, opts, name: via(user_id))
  end

  def find(user_id) do
    case Registry.lookup(NotificationService.SessionRegistry, user_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def register_channel(user_id, channel_pid) do
    GenServer.cast(via(user_id), {:register_channel, channel_pid})
  end

  def ack(user_id, notification_id) do
    GenServer.cast(via(user_id), {:ack, notification_id})
  end

  @impl true
  def init(%{user_id: user_id} = opts) do
    :ok = Phoenix.PubSub.subscribe(PubSub, "user:#{user_id}")

    state = %{
      user_id: user_id,
      channel_pid: opts[:channel_pid],
      pending_acks: %{}
    }

    if state.channel_pid, do: Process.monitor(state.channel_pid)
    {:ok, state}
  end

  @impl true
  def handle_info({:new_notification, notification}, state) do
    deliver(notification, state)
  end

  def handle_info({:retry, notification_id}, state) do
    case state.pending_acks[notification_id] do
      nil ->
        {:noreply, state}

      retries when retries >= @max_retries ->
        notification = Notifications.get_notification!(notification_id)
        Notifications.mark_failed(notification)
        {:noreply, drop_pending(state, notification_id)}

      retries ->
        notification = Notifications.get_notification!(notification_id)
        state = put_in(state.pending_acks[notification_id], retries + 1)
        deliver(notification, state)
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{channel_pid: pid} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:register_channel, channel_pid}, state) do
    Process.monitor(channel_pid)
    {:noreply, %{state | channel_pid: channel_pid}}
  end

  def handle_cast({:ack, notification_id}, state) do
    case state.pending_acks[notification_id] do
      nil ->
        {:noreply, state}

      _ ->
        Notifications.get_notification!(notification_id) |> Notifications.mark_delivered()
        {:noreply, drop_pending(state, notification_id)}
    end
  end

  defp deliver(notification, state) do
    if state.channel_pid && Process.alive?(state.channel_pid) do
      send(state.channel_pid, {:push_notification, notification})
      state = put_in(state.pending_acks[notification.id], 0)
      schedule_retry(notification.id, 0)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  defp schedule_retry(notification_id, attempt) do
    delay = (@base_retry_ms * :math.pow(2, attempt)) |> round()
    Process.send_after(self(), {:retry, notification_id}, delay)
  end

  defp drop_pending(state, id), do: update_in(state.pending_acks, &Map.delete(&1, id))
  defp via(user_id), do: {:via, Registry, {NotificationService.SessionRegistry, user_id}}
end

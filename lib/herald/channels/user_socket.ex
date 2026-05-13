defmodule NotificationService.UserSocket do
  use Phoenix.Socket

  channel "notifications:*", NotificationService.Channels.NotificationChannel

  @max_age 14 * 24 * 3600

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user_socket", token, max_age: @max_age) do
      {:ok, user_id} -> {:ok, assign(socket, :user_id, user_id)}
      {:error, _}    -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
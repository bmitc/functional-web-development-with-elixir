defmodule IslandsInterfaceWeb.GameChannel do
  @moduledoc """
  Phoenix generated module
  """

  use IslandsInterfaceWeb, :channel

  # alias IslandsEngine.Game
  # alias IslandsEngine.GameSupervisor

  @impl Phoenix.Channel
  def join("game:" <> _player, _payload, socket) do
    {:ok, socket}
  end

  @impl Phoenix.Channel
  def handle_in("reply_hello", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("push_hello", payload, socket) do
    push(socket, "pushed_hello", payload)
    {:noreply, socket}
  end

  def handle_in("broadcast_hello", payload, socket) do
    broadcast!(socket, "broadcasted_hello", payload)
    {:noreply, socket}
  end

  # # Add authorization logic here as required.
  # @spec authorized?(any()) :: boolean()
  # defp authorized?(_payload) do
  #   true
  # end
end

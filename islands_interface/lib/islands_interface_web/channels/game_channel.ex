defmodule IslandsInterfaceWeb.GameChannel do
  @moduledoc """
  Phoenix generated module
  """

  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.Game
  alias IslandsEngine.GameSupervisor

  ########################################################################
  #### Phoenix.Channel callbacks #########################################
  ########################################################################

  @impl Phoenix.Channel
  def join("game:" <> _player, _payload, socket) do
    {:ok, socket}
  end

  ########################################################################
  #### Phoenix.Channel callbacks: Examples ###############################
  ########################################################################

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

  ########################################################################
  #### Phoenix.Channel callbacks: Islands game events ####################
  ########################################################################

  def handle_in("new_game", _payload, socket) do
    socket
    |> get_player1_name_from_socket()
    |> GameSupervisor.start_game()
    |> case do
      {:ok, _pid} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("stop_game", _payload, socket) do
    socket
    |> get_player1_name_from_socket()
    |> GameSupervisor.stop_game()
    |> case do
      :ok -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player2, socket) do
    socket
    |> get_player1_name_from_socket()
    |> Game.create_via_tuple()
    |> Game.add_player(player2)
    |> case do
      :ok ->
        # This is broadcasted so that each player channel session can get the message
        broadcast!(socket, "player_added", %{message: "new player just joined: #{player2}"})

        {:noreply, socket}

      :error ->
        {:reply, :error, socket}
    end
  end

  ########################################################################
  #### Private functions #################################################
  ########################################################################

  # # Matches on player 1's name from the channel topic and returns a via tuple
  # # for that name in order to find the GenServer game process
  # @spec via(String.t()) :: Game.via_tuple()
  # defp via("game:" <> player1_name), do: Game.create_via_tuple(player1_name)

  # Returns player 1's name from the given socket
  @spec get_player1_name_from_socket(Phoenix.Socket.t()) :: String.t()
  defp get_player1_name_from_socket(socket) do
    "game:" <> player1_name = socket.topic
    player1_name
  end

  # # Add authorization logic here as required.
  # @spec authorized?(any()) :: boolean()
  # defp authorized?(_payload) do
  #   true
  # end
end

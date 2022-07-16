defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  import IslandsEngine.Game, only: [is_game_reference: 1]

  alias IslandsEngine.Game

  setup do
    {:ok, _, socket} =
      IslandsInterfaceWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(IslandsInterfaceWeb.GameChannel, "game:moon", %{screen_name: "moon"})

    %{socket: socket}
  end

  test "reply_hello replies with status ok", %{socket: socket} do
    ref = push(socket, "reply_hello", %{"hello" => "there"})
    assert_reply(ref, :ok, %{"hello" => "there"})
  end

  test "push_hello broadcasts to game:lobby", %{socket: socket} do
    push(socket, "push_hello", %{"hello" => "all"})
    assert_push("pushed_hello", %{"hello" => "all"})
  end

  test "broadcast_hello pushes to the client", %{socket: socket} do
    push(socket, "broadcast_hello", %{"some" => "data"})
    assert_broadcast("broadcasted_hello", %{"some" => "data"})
  end

  test "starting a new game twice", %{socket: socket} do
    ref = push(socket, "new_game")
    assert_reply(ref, :ok)

    # Try to start a new game with the same subtopic
    ref = push(socket, "new_game")
    assert_reply(ref, :error, %{reason: reason})
    assert String.contains?(reason, ":already_started")

    stop_game(socket)
  end

  test "starting a new game and adding a second player", %{socket: socket} do
    ref = push(socket, "new_game")
    assert_reply(ref, :ok)

    # Check that there's a player1 but no player2
    assert get_game_state().player1.name == "moon"
    assert is_nil(get_game_state().player2.name)

    # Add a second player and check that player2 has the correct name
    push(socket, "add_player", "sun")
    assert_broadcast("player_added", _payload)
    assert get_game_state().player2.name == "sun"

    stop_game(socket)
  end

  ########################################################################
  #### Private functions #################################################
  ########################################################################

  @spec game_state(Game.game_reference()) :: Game.t()
  defp game_state(game_reference) when is_game_reference(game_reference) do
    :sys.get_state(game_reference)
  end

  @spec get_game_state() :: Game.t()
  defp get_game_state() do
    "moon" |> Game.create_via_tuple() |> game_state()
  end

  # Stops the game associated with the given socket and asserts that the game
  # exists and is stopped correctly.
  @spec stop_game(Phoenix.Socket) :: :ok
  defp stop_game(socket) do
    ref = push(socket, "stop_game")
    assert_reply(ref, :ok, _stopping_game)
    :ok
  end
end

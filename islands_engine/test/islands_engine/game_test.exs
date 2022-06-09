defmodule IslandsEngine.GameTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Game
  alias IslandsEngine.Island
  alias IslandsEngine.Rules

  test "starting the game GenServer" do
    {:ok, game} = Game.start_link("Frank")
    state_data = game_state(game)
    assert state_data.player1.name == "Frank"
    assert is_nil(state_data.player2.name)
  end

  test "adding a player" do
    {:ok, game} = Game.start_link("Frank")
    assert Game.add_player(game, "Dweezil") == :ok
    state_data = game_state(game)
    assert state_data.player2.name == "Dweezil"
  end

  test "positioning an island" do
    {:ok, game} = Game.start_link("Fred")
    assert Game.add_player(game, "Wilma") == :ok
    state_data = game_state(game)
    assert state_data.rules.state == :players_set

    assert Game.position_island(game, :player1, :square, 1, 1) == :ok
    state_data = game_state(game)
    assert Map.keys(state_data.player1.board) == [:square]

    assert Island.equal?(
             state_data.player1.board.square,
             %Island{
               coordinates:
                 MapSet.new([
                   Coordinate.new(1, 1) |> elem(1),
                   Coordinate.new(2, 1) |> elem(1),
                   Coordinate.new(1, 2) |> elem(1),
                   Coordinate.new(2, 2) |> elem(1)
                 ]),
               hit_coordinates: MapSet.new()
             }
           )

    assert Game.position_island(game, :player1, :dot, 12, 1) == {:error, :invalid_coordinate}
    assert Game.position_island(game, :player1, :wrong, 1, 1) == {:error, :invalid_island_type}
    assert Game.position_island(game, :player1, :l_shape, 10, 10) == {:error, :invalid_coordinate}

    state_data =
      :sys.replace_state(game, fn state_data ->
        %Game{state_data | rules: %Rules{state: :player1_turn}}
      end)

    assert state_data.rules.state == :player1_turn
    assert Game.position_island(game, :player1, :dot, 5, 5) == :error
  end

  test "setting islands" do
    {:ok, game} = Game.start_link("Dino")

    # Add the second player
    assert Game.add_player(game, "Pebbles") == :ok

    # An error is expected since player1 has not positioned all their islands yet
    assert Game.set_islands(game, :player1) == {:error, :not_all_islands_positioned}

    # Position player1's islands
    Game.position_island(game, :player1, :atoll, 1, 1)
    Game.position_island(game, :player1, :dot, 1, 4)
    Game.position_island(game, :player1, :l_shape, 1, 5)
    Game.position_island(game, :player1, :s_shape, 5, 1)
    Game.position_island(game, :player1, :square, 5, 5)

    # Check that we can set player1's islands
    assert {:ok, %{} = board} = Game.set_islands(game, :player1)

    # Check that at least all the island types are on the board
    assert MapSet.equal?(
             MapSet.new(Map.keys(board)),
             MapSet.new([:atoll, :dot, :l_shape, :s_shape, :square])
           )

    # Check that we're in the correc state and that player1 has set thir islands
    state_data = game_state(game)
    assert state_data.rules.state == :players_set
    assert state_data.rules.player1 == :islands_set
  end

  test "guessing coordinate" do
    {:ok, game} = Game.start_link("Miles")

    # Check that guessing a coordinate too early is disallowed
    assert Game.guess_coordinate(game, :player1, 1, 1) == :error

    # Add a second player and position an island for both players
    Game.add_player(game, "Trane")
    Game.position_island(game, :player1, :dot, 1, 1)
    Game.position_island(game, :player2, :square, 1, 1)

    # Manually set the state to player1's turn
    state_data =
      :sys.replace_state(game, fn state_data ->
        %Game{state_data | rules: %Rules{state: :player1_turn}}
      end)

    assert state_data.rules.state == :player1_turn

    # Check a wrong guess by player1
    assert Game.guess_coordinate(game, :player1, 5, 5) == {:miss, :none, :no_win}

    # Check that player1 can't guess again
    assert Game.guess_coordinate(game, :player1, 3, 1) == :error

    # Check that it's player2's turn
    assert game_state(game).rules.state == :player2_turn

    # Check that player2's successful guess for :dot wins the game
    assert Game.guess_coordinate(game, :player2, 1, 1) == {:hit, :dot, :win}
  end

  test "game process name registration" do
    # Start a game process
    assert {:ok, game_pid} = Game.start_link("Lena")

    # Check that there's a GenServer process registered under the name "Lena"
    # with the appropriate default Game state
    assert %Game{player1: %{}, player2: %{}, rules: %Rules{}} =
             game_state({:via, Registry, {Registry.Game, "Lena"}})

    # Try to start another game process with the same name and get an already started error
    assert Game.start_link("Lena") == {:error, {:already_started, game_pid}}
  end

  @spec game_state(pid()) :: Game.t()
  defp game_state(game_pid), do: :sys.get_state(game_pid)
end

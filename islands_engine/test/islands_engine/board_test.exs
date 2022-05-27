defmodule IslandsEngine.BoardTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.Board
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Island

  test "a full board game" do
    board = Board.new()

    # Test populating the first island on the board
    {:ok, square_coordinate} = Coordinate.new(1, 1)
    {:ok, square} = Island.new(:square, square_coordinate)
    board = Board.position_island(board, :square, square)
    refute board == {:error, :overlapping_island}

    # Test for positioning an island incorrectly by overlapping with an existing island
    {:ok, dot_coordinate} = Coordinate.new(2, 2)
    {:ok, dot} = Island.new(:dot, dot_coordinate)
    assert Board.position_island(board, :dot, dot) == {:error, :overlapping_island}

    # Test for positioning an island successfully
    {:ok, new_dot_coordinate} = Coordinate.new(3, 3)
    {:ok, new_dot} = Island.new(:dot, new_dot_coordinate)
    board = Board.position_island(board, :dot, new_dot)
    refute board == {:error, :overlapping_island}

    # Test for a miss
    {:ok, guess_coordinate} = Coordinate.new(10, 10)
    assert {:miss, :none, :no_win, board} = Board.guess(board, guess_coordinate)

    # Test for a hit that doesn't forest an island or win
    {:ok, hit_coordinate} = Coordinate.new(1, 1)
    assert {:hit, :none, :no_win, board} = Board.guess(board, hit_coordinate)

    # Test for a win

    # Set the hit_coordinates to simply be the square's coordinates to fake
    # all of the coordinates being hit and thus the square being forested
    square = %{square | hit_coordinates: square.coordinates}

    # Reposition the square
    board = Board.position_island(board, :square, square)

    {:ok, win_coordinate} = Coordinate.new(3, 3)

    assert {:hit, :dot, :win, _board} = Board.guess(board, win_coordinate)
  end
end

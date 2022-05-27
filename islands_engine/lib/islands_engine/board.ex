defmodule IslandsEngine.Board do
  @moduledoc """
  Represents a game board
  """

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Island

  @type t() :: %{optional(Island.island_type()) => Island.t()}

  @doc """
  Creates a new board
  """
  @spec new() :: __MODULE__.t()
  def new(), do: %{}

  @doc """
  Positions the given island on the board with the given key, updating its
  position if it has already been positioned before. An error is returned
  if the island overlaps with any other islands.
  """
  @spec position_island(__MODULE__.t(), atom(), Island.t()) ::
          __MODULE__.t() | {:error, :overlapping_island}
  def position_island(%{} = board, key, %Island{} = island) do
    if overlaps_existing_island?(board, key, island) do
      {:error, :overlapping_island}
    else
      Map.put(board, key, island)
    end
  end

  @doc """
  Checks if all the island types have been positioned on the board
  """
  @spec all_islands_positioned?(__MODULE__.t()) :: boolean()
  def all_islands_positioned?(%{} = board) do
    Enum.all?(Island.types(), fn island_type -> Map.has_key?(board, island_type) end)
    # Note: islands on the board must have a position by virtue of how they are put
    # on the board, so checking if the islands have a position is not applicable.
  end

  @spec guess(__MODULE__.t(), Coordinate.t()) ::
          {:hit | :miss, atom() | :none, :win | :no_win, __MODULE__.t()}
  def guess(board, %Coordinate{} = coordinate) do
    board
    |> check_all_islands(coordinate)
    |> guess_response(board)
  end

  # Checks if the given island associated with the given key overlaps any existing
  # islands on the board
  @spec overlaps_existing_island?(__MODULE__.t(), atom(), Island.t()) :: boolean()
  defp overlaps_existing_island?(%{} = board, new_key, %Island{} = new_island) do
    Enum.any?(board, fn {key, island} ->
      key != new_key and Island.overlaps?(island, new_island)
    end)
  end

  @spec check_all_islands(__MODULE__.t(), Coordinate.t()) :: {atom(), Island.t()} | :miss
  defp check_all_islands(%{} = board, %Coordinate{} = coordinate) do
    Enum.find_value(board, :miss, fn {key, island} ->
      case Island.guess(island, coordinate) do
        {:hit, island} -> {key, island}
        :miss -> false
      end
    end)
  end

  @spec guess_response({atom(), Island.t()} | :miss, __MODULE__.t()) ::
          {:hit | :miss, atom() | :none, :win | :no_win, __MODULE__.t()}
  defp guess_response({key, island}, %{} = board) do
    board = %{board | key => island}
    {:hit, forest_check(board, key), win_check(board), board}
  end

  defp guess_response(:miss, board), do: {:miss, :none, :no_win, board}

  # Checks if the island associated with the key is forested or not.
  # If forested, then the key is returned. Otherwise, :none is returned.
  @spec forest_check(__MODULE__.t(), atom()) :: atom() | :none
  defp forest_check(board, key) do
    if forested?(board, key) do
      key
    else
      :none
    end
  end

  # Checks if the island associated with the key is forested or not
  @spec forested?(__MODULE__.t(), atom()) :: boolean()
  defp forested?(board, key) do
    board
    |> Map.fetch!(key)
    |> Island.forested?()
  end

  # If all islands on the board are forested, then :win is returned.
  # Otherwise, :no_win is returned.
  @spec win_check(__MODULE__.t()) :: :win | :no_win
  defp win_check(board) do
    if all_forested?(board) do
      :win
    else
      :no_win
    end
  end

  # Checks if all the islands on the board are forested or not
  @spec all_forested?(__MODULE__.t()) :: boolean()
  defp all_forested?(board) do
    Enum.all?(board, fn {_key, island} -> Island.forested?(island) end)
  end
end

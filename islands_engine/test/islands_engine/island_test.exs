defmodule IslandsEngine.IslandTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Island

  test "creating l-shaped island" do
    {:ok, coordinate} = Coordinate.new(4, 6)
    {:ok, l_shaped_island} = Island.new(:l_shape, coordinate)

    assert Island.equal?(
             l_shaped_island,
             %Island{
               coordinates:
                 MapSet.new([
                   Coordinate.new(4, 6) |> elem(1),
                   Coordinate.new(5, 6) |> elem(1),
                   Coordinate.new(6, 6) |> elem(1),
                   Coordinate.new(6, 7) |> elem(1)
                 ]),
               hit_coordinates: MapSet.new()
             }
           )
  end

  test "creating an island with an invalid type" do
    {:ok, coordinate} = Coordinate.new(4, 6)
    assert Island.new(:wrong, coordinate) == {:error, :invalid_island_type}
  end

  test "creating an l-shaped island that generates invalid coordinates" do
    {:ok, coordinate} = Coordinate.new(10, 10)
    assert Island.new(:l_shape, coordinate) == {:error, :invalid_coordinate}
  end

  test "islands overlap as expected" do
    {:ok, square_coordinate} = Coordinate.new(1, 1)
    {:ok, square} = Island.new(:square, square_coordinate)

    {:ok, dot_coordinate} = Coordinate.new(1, 2)
    {:ok, dot} = Island.new(:dot, dot_coordinate)

    {:ok, l_shape_coordinate} = Coordinate.new(5, 5)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_coordinate)

    assert Island.overlaps?(square, dot)
    refute Island.overlaps?(square, l_shape)
    refute Island.overlaps?(dot, l_shape)
  end

  test "guessing hits and misses" do
    {:ok, dot_coordinate} = Coordinate.new(4, 4)
    {:ok, dot} = Island.new(:dot, dot_coordinate)
    {:ok, coordinate} = Coordinate.new(2, 2)

    assert Island.guess(dot, coordinate) == :miss

    {:ok, new_coordinate} = Coordinate.new(4, 4)

    assert {:hit, dot} = Island.guess(dot, new_coordinate)

    assert Island.forested?(dot)
  end
end

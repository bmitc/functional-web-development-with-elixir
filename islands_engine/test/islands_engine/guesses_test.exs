defmodule IslandsEngine.GuessesTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Guesses

  test "hit or miss" do
    {:ok, coordinate1} = Coordinate.new(8, 3)
    {:ok, coordinate2} = Coordinate.new(9, 7)
    {:ok, coordinate3} = Coordinate.new(1, 2)

    guesses =
      Guesses.new()
      |> Guesses.add(:hit, coordinate1)
      |> Guesses.add(:hit, coordinate2)
      |> Guesses.add(:miss, coordinate3)

    assert guesses == %Guesses{
             hits: MapSet.new([coordinate1, coordinate2]),
             misses: MapSet.new([coordinate3])
           }
  end
end

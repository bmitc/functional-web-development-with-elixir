defmodule IslandsEngine.CoordinateTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.Coordinate

  test "valid coordinate" do
    assert Coordinate.new(1, 1) == {:ok, %Coordinate{row: 1, column: 1}}
  end

  test "invalid coordinates" do
    assert Coordinate.new(-1, 1) == {:error, :invalid_coordinate}
    assert Coordinate.new(11, 1) == {:error, :invalid_coordinate}
  end
end

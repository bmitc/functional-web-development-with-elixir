defmodule IslandsEngine.PlayerTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.Board
  alias IslandsEngine.Guesses
  alias IslandsEngine.Player

  test "creating a default player" do
    player = Player.new()
    assert is_nil(player.name)
    assert player.guesses == Guesses.new()
    assert player.board == Board.new()
  end

  test "creating player with a name" do
    player = Player.new("Larry Bird")
    assert player.name == "Larry Bird"
  end
end

defmodule IslandsEngine.RulesTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias IslandsEngine.Rules

  test "transitioning from :initialized to :players_set" do
    rules = Rules.new()
    assert rules == %Rules{state: :initialized}

    {:ok, rules} = Rules.check(rules, :add_player)
    assert rules.state == :players_set
  end

  test "positioning islands does not transition from the :players_set state" do
    rules = %Rules{Rules.new() | state: :players_set}
    assert rules.state == :players_set

    {:ok, rules} = Rules.check(rules, {:position_islands, :player1})
    assert rules.state == :players_set

    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set
  end

  test "setting islands" do
    rules = %Rules{Rules.new() | state: :players_set}
    assert rules.state == :players_set

    # Let player1 set their islands, multiple times if they like,
    # but check that they can't position islands after setting them
    {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
    {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
    assert rules.state == :players_set
    assert rules.player1 == :islands_set
    assert rules.player2 == :islands_not_set
    assert Rules.check(rules, {:position_islands, :player1}) == :error

    # Let player2 position their islands
    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set
    assert rules.player1 == :islands_set
    assert rules.player2 == :islands_not_set

    # Let player2 set their islands but check that they can't position
    # islands after setting them or set them after the state transition
    {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
    assert rules.state == :player1_turn
    assert rules.player1 == :islands_set
    assert rules.player2 == :islands_set
    assert Rules.check(rules, {:position_islands, :player2}) == :error
    assert Rules.check(rules, {:set_islands, :player2}) == :error
  end

  test "players taking turns" do
    rules = %Rules{Rules.new() | state: :player1_turn}
    assert rules.state == :player1_turn

    # Disallow player2 guessing while it is player1's turn
    assert Rules.check(rules, {:guess_coordinate, :player2}) == :error

    # Allow player1 to guess and then switch to player2's turn
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})
    assert rules.state == :player2_turn

    # Allow player2 to guess and then switch to player1's turn
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})
    assert rules.state == :player1_turn
  end

  test "checking for a win" do
    rules = %Rules{Rules.new() | state: :player1_turn}

    # There's no win, so the state should remain unchanged
    {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
    assert rules.state == :player1_turn

    # There's a win, so transition to game over
    {:ok, rules} = Rules.check(rules, {:win_check, :win})
    assert rules.state == :game_over
  end

  test "full state transitions" do
    rules = Rules.new()
    assert rules.state == :initialized

    # Add a player and check that the state transitions
    {:ok, rules} = Rules.check(rules, :add_player)
    assert rules.state == :players_set

    # Each player should be able to move an island the state stay in :players_set
    {:ok, rules} = Rules.check(rules, {:position_islands, :player1})
    assert rules.state == :players_set
    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set

    # When one player sets their islands, they should no longer be able to position
    # them, but the other player should be able to
    {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
    assert rules.state == :players_set
    assert Rules.check(rules, {:position_islands, :player1}) == :error
    {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
    assert rules.state == :players_set

    # When both players set their islands, the state should transition
    {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
    assert rules.state == :player1_turn

    # The players should be able to alternate guess, starting with player1 and
    # not allowing multiple guesses by one player
    assert Rules.check(rules, {:guess_coordinate, :player2}) == :error
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})
    assert rules.state == :player2_turn
    assert Rules.check(rules, {:guess_coordinate, :player1}) == :error
    {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})
    assert rules.state == :player1_turn

    # Any guess that doesn't result in a win should not transition the state
    # from one of the player's turn, but a win should transition to a game over
    {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
    assert rules.state == :player1_turn
    {:ok, rules} = Rules.check(rules, {:win_check, :win})
    assert rules.state == :game_over
  end
end

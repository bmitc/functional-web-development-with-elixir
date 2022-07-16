defmodule IslandsEngine.GameSupervisorTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import IslandsEngine.Game, only: [is_game_reference: 1]

  alias IslandsEngine.Game
  alias IslandsEngine.GameSupervisor

  @game_timeout_ms Game.get_timeout_ms()

  setup do
    # Reset the game state ETS table before each test
    :ets.delete_all_objects(:game_state)
    :ok
  end

  test "game supervisor starts and stops game" do
    # Check that there are no workers under GameSupervisor
    Supervisor.which_children(GameSupervisor)

    assert %{active: 0, specs: 0, supervisors: 0, workers: 0} =
             Supervisor.count_children(GameSupervisor)

    via = Game.create_via_tuple("Cassatt")

    # Check that there's no existing game process for "Cassatt"
    refute GenServer.whereis(via)

    # Dynamically start a game for "Cassatt" under the GameSupervisor
    {:ok, game_pid} = GameSupervisor.start_game("Cassatt")

    assert GenServer.whereis(via) == game_pid

    assert Supervisor.count_children(GameSupervisor) == %{
             active: 1,
             specs: 1,
             supervisors: 0,
             workers: 1
           }

    assert Supervisor.which_children(GameSupervisor) == [
             {:undefined, game_pid, :worker, [IslandsEngine.Game]}
           ]

    # Stop the "Cassatt" game
    assert GameSupervisor.stop_game("Cassatt") == :ok

    # Check that the "Cassatt" GenServer has stopped and is no longer registered
    refute Process.alive?(game_pid)
    refute GenServer.whereis(via)
  end

  @tag :skip
  test "game times out after #{@game_timeout_ms * 1000} seconds" do
    {:ok, game_pid} = GameSupervisor.start_game("Cassatt")

    assert Process.alive?(game_pid)

    :timer.sleep(@game_timeout_ms + 1000)

    refute Process.alive?(game_pid)
  end

  test "game interaction" do
    {:ok, game_pid} = GameSupervisor.start_game("Hopper")

    via = Game.create_via_tuple("Hopper")

    # Check that the started game is the same as returned by the registry
    assert GenServer.whereis(via) == game_pid

    assert Game.add_player(via, "Hockney") == :ok

    state_data = game_state(via)
    assert state_data.player1.name == "Hopper"
    assert state_data.player2.name == "Hockney"

    # Check that the "Hopper" game is killed
    assert Process.exit(game_pid, :kaboom) == true

    # Kill the test process after 5 seconds if the game is not restarted properly
    :timer.exit_after(5000, "Hopper game not restarted by GameSupervisor")
    wait_until_restarted(via)

    # Check that it is restarted but with a different PID
    restarted_game_pid = GenServer.whereis(via)
    assert restarted_game_pid != game_pid
    assert is_pid(restarted_game_pid)

    GameSupervisor.stop_game("Hopper")
  end

  test "game state recovers" do
    {:ok, game_pid} = GameSupervisor.start_game("Morandi")

    [{"Morandi", state}] = :ets.lookup(:game_state, "Morandi")

    # Check that the ETS game state was initialized properly
    assert state.player1.name == "Morandi"
    assert is_nil(state.player2.name)

    assert Game.add_player(game_pid, "Rothko") == :ok

    [{"Morandi", state}] = :ets.lookup(:game_state, "Morandi")

    # Check that the ETS game state was updated properly
    assert state.player1.name == "Morandi"
    assert state.player2.name == "Rothko"

    # Kill the game's PID process
    Process.exit(game_pid, :kaboom)

    via = Game.create_via_tuple("Morandi")

    # Kill the test process after 5 seconds if the game is not restarted properly
    :timer.exit_after(5000, "Hopper game not restarted by GameSupervisor")
    wait_until_restarted(via)

    # Get the restarted game process state
    state = game_state(via)

    # Check that the game state was restored from ETS properly
    assert state.player1.name == "Morandi"
    assert state.player2.name == "Rothko"

    # Check that the ETS game state was left alone during the
    # game state restoration process
    [{"Morandi", state}] = :ets.lookup(:game_state, "Morandi")
    assert state.player1.name == "Morandi"
    assert state.player2.name == "Rothko"

    GameSupervisor.stop_game("Morandi")
  end

  test "game state is cleaned up" do
    {:ok, game_pid} = GameSupervisor.start_game("Agnes")

    # Check that the via tuple matches the PID of the game we just started
    via = Game.create_via_tuple("Agnes")
    assert GenServer.whereis(via) == game_pid

    # Stop the game with a normal stop message
    assert GameSupervisor.stop_game("Agnes") == :ok

    # Check that the GenServer game process is not alive anymore
    refute Process.alive?(game_pid)

    # Check that the game wasn't restarted
    refute GenServer.whereis(via)

    # Check that the game state ETS table was cleaned up properly
    assert :ets.lookup(:game_state, "Agnes") == []
  end

  ########################################################################
  #### Private functions #################################################
  ########################################################################

  # Helper function to test if a process has restarted yet.
  # Use `:timer.exit_after` before this function as a timeout mechanism.
  @spec wait_until_restarted(tuple()) :: nil
  defp wait_until_restarted(via_tuple) do
    unless GenServer.whereis(via_tuple) do
      wait_until_restarted(via_tuple)
    end
  end

  @spec game_state(Game.game_reference()) :: Game.t()
  defp game_state(game_reference) when is_game_reference(game_reference) do
    :sys.get_state(game_reference)
  end
end

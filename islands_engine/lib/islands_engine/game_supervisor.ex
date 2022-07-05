defmodule IslandsEngine.GameSupervisor do
  @moduledoc """
  Supervisor for all islands engine game processes
  """

  use DynamicSupervisor

  alias IslandsEngine.Game

  ########################################################################
  #### Client interface ##################################################
  ########################################################################

  @doc """
  Starts the `GameSupervisor`
  """
  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts an islands game with the given `player_1_name` underneath the `GameSupervisor`
  """
  @spec start_game(String.t()) :: DynamicSupervisor.on_start_child()
  def start_game(player_1_name) when is_binary(player_1_name) do
    DynamicSupervisor.start_child(__MODULE__, Game.child_spec(player_1_name))
  end

  @doc """
  Stops the islands game that was started with the given `player_1_name`
  """
  @spec stop_game(String.t()) :: :ok | {:error, :not_found}
  def stop_game(player_1_name) when is_binary(player_1_name) do
    :ets.delete(:game_state, player_1_name)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(player_1_name))
  end

  ########################################################################
  #### DynamicSupervisor callbacks #######################################
  ########################################################################

  @impl DynamicSupervisor
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  ########################################################################
  #### Private functions #################################################
  ########################################################################

  # Find the PID of the process associated with the given `player_1_name`
  @spec pid_from_name(String.t()) :: pid() | nil
  defp pid_from_name(player_1_name) when is_binary(player_1_name) do
    player_1_name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end

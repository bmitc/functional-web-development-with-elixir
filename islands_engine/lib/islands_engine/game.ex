defmodule IslandsEngine.Game do
  @moduledoc """
  Client interface functions for an islands game GenServer
  """

  @behaviour Access

  use GenServer

  import IslandsEngine.Player, only: [is_player_role: 1]

  alias IslandsEngine.Board
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Guesses
  alias IslandsEngine.Island
  alias IslandsEngine.Player
  alias IslandsEngine.Rules

  @enforce_keys [:player1, :player2, :rules]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          player1: Player.t(),
          player2: Player.t(),
          rules: Rules.t()
        }

  # Represents the call messages that can be sent to the game GenServer
  @typep call_messages() ::
           {:add_player, name :: String.t()}
           | {:position_island, Player.role(), Island.island_type(), row :: pos_integer(),
              column :: pos_integer()}
           | {:set_islands, Player.role()}
           | {:guess_coordinate, Player.role(), row :: pos_integer(), column :: pos_integer()}

  # @player_roles Player.roles()

  ########################################################################
  #### Client interface ##################################################
  ########################################################################

  @doc """
  Starts an islands game GenServer
  """
  @spec start_link(String.t()) ::
          {:ok, pid()}
          | {:error, {:already_started, pid()}}
          | {:error, any()}
          | {:stop, any()}
          | :ignore
  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  @doc """
  Adds a second player to the game
  """
  @spec add_player(pid(), String.t()) :: :ok | :error
  def add_player(game_pid, name) when is_pid(game_pid) and is_binary(name) do
    GenServer.call(game_pid, {:add_player, name})
  end

  @doc """
  Positions a player's island
  """
  @spec position_island(pid(), Player.role(), Island.island_type(), pos_integer(), pos_integer()) ::
          :ok
          | :error
          | {:error, :invalid_coordinate}
          | {:error, :invalid_island_type}
          | {:error, :overlapping_island}
  def position_island(game_pid, player_role, island_type, row, column)
      when is_pid(game_pid) and is_player_role(player_role) do
    GenServer.call(game_pid, {:position_island, player_role, island_type, row, column})
  end

  @doc """
  Sets a player's island positions
  """
  @spec set_islands(pid(), Player.role()) ::
          :ok | {:ok, Board.t()} | :error | {:error, :not_all_islands_positioned}
  def set_islands(game_pid, player_role) when is_pid(game_pid) and is_player_role(player_role) do
    GenServer.call(game_pid, {:set_islands, player_role})
  end

  @doc """
  Guesses a coordinate for the given player
  """
  @spec guess_coordinate(pid(), Player.role(), pos_integer(), pos_integer()) ::
          {:hit | :miss, Island.island_type(), :win | :no_win}
          | :error
          | {:error, :invalid_coordinate}
  def guess_coordinate(game_pid, player_role, row, column)
      when is_player_role(player_role) do
    GenServer.call(game_pid, {:guess_coordinate, player_role, row, column})
  end

  ########################################################################
  #### GenServer callbacks ###############################################
  ########################################################################

  @impl GenServer
  def init(name) do
    {:ok, %__MODULE__{player1: Player.new(name), player2: Player.new(), rules: Rules.new()}}
  end

  @impl GenServer
  @spec handle_call(call_messages(), {pid(), any()}, __MODULE__.t()) ::
          {:reply, __MODULE__.t(), __MODULE__.t()}
          | {:reply, :error, __MODULE__.t()}
          | {:reply, {:error, :not_all_islands_positioned}, __MODULE__.t()}
  def handle_call({:add_player, name}, _from, state) do
    case Rules.check(state.rules, :add_player) do
      {:ok, rules} ->
        state
        |> update_player2_name(name)
        |> update_rules(rules)
        |> reply_success(:ok)

      :error ->
        {:reply, :error, state}
    end
  end

  def handle_call({:position_island, player_role, island_type, row, column}, _from, state) do
    board = player_board(state, player_role)

    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player_role}),
         {:ok, coordinate} <- Coordinate.new(row, column),
         {:ok, island} <- Island.new(island_type, coordinate),
         board <- Board.position_island(board, island_type, island) do
      state
      |> update_board(player_role, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error = check_error ->
        {:reply, check_error, state}

      {:error, :invalid_coordinate} = coordinate_new_error ->
        {:reply, coordinate_new_error, state}

      {:error, :invalid_island_type} = coordinate_or_island_new_error ->
        {:reply, coordinate_or_island_new_error, state}

      {:error, :overlapping_island} = position_island_error ->
        {:reply, position_island_error, state}
    end
  end

  def handle_call({:set_islands, player_role}, _from, state) do
    board = player_board(state, player_role)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player_role}),
         true <- Board.all_islands_positioned?(board) do
      state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  def handle_call({:guess_coordinate, player_role, row, column}, _from, state) do
    opponent_role = opponent(player_role)
    opponent_board = player_board(state, opponent_role)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player_role}),
         {:ok, coordinate} <- Coordinate.new(row, column),
         {hit_or_miss, forested_island, win_status, opponent_board} =
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state
      |> update_board(opponent_role, opponent_board)
      |> update_guesses(player_role, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error = rules_check_error ->
        {:reply, rules_check_error, state}

      {:error, :invalid_coordinate} = coordinate_new_error ->
        {:reply, coordinate_new_error, state}
    end
  end

  ########################################################################
  #### Access callbacks ##################################################
  ########################################################################

  # The Access behaviour is implemented to support accessing struct key values via the
  # `state.[key]` syntax and to use `update_in` using such syntax as the path.
  # Popping a key from the struct is not supported.

  @impl Access
  def fetch(state, key), do: Map.fetch(state, key)

  @impl Access
  def get_and_update(state, key, update_fun), do: Map.get_and_update(state, key, update_fun)

  @impl Access
  def pop(_state, _key), do: raise(RuntimeError, "#{__MODULE__} does not support popping a key.")

  ########################################################################
  #### Private functions #################################################
  ########################################################################

  @spec update_player2_name(__MODULE__.t(), String.t()) :: __MODULE__.t()
  defp update_player2_name(state, name) do
    %__MODULE__{state | player2: Player.update_name(state.player2, name)}
  end

  @spec update_rules(__MODULE__.t(), Rules.t()) :: __MODULE__.t()
  defp update_rules(state, rules), do: %__MODULE__{state | rules: rules}

  @spec reply_success(__MODULE__.t(), reply) :: {:reply, reply, __MODULE__.t()} when reply: any()
  defp reply_success(state, reply), do: {:reply, reply, state}

  @spec player_board(__MODULE__.t(), Player.role()) :: Board.t()
  defp player_board(state, player), do: Map.get(state, player).board

  @spec update_board(__MODULE__.t(), Player.role(), Board.t()) :: __MODULE__.t()
  defp update_board(state, player_role, board) do
    # Map.update!(state, player_role, fn %Player{} = player -> %Player{player | board: board} end)
    Map.put(state, player_role, %Player{state[player_role] | board: board})
  end

  @spec update_guesses(__MODULE__.t(), Player.role(), :hit | :miss, Coordinate.t()) ::
          __MODULE__.t()
  defp update_guesses(state, player_role, hit_or_miss, coordinate) do
    update_in(state[player_role].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  @spec opponent(Player.role()) :: Player.role()
  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  @spec via_tuple(String.t()) :: {:via, Registry, {Registry.Game, String.t()}}
  defp via_tuple(name), do: {:via, Registry, {Registry.Game, name}}
end

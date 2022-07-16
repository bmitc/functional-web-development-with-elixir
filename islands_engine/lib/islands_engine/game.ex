defmodule IslandsEngine.Game do
  @moduledoc """
  Client interface functions for an islands game GenServer
  """

  @behaviour Access

  use GenServer, restart: :transient

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

  # 30 minutes
  @timeout_ms 108_000

  @typedoc """
  Represents an integer timeout value in milliseconds
  """
  @type timeout_ms() :: non_neg_integer()

  @typedoc """
  Represents a `:via` tuple for referencing GenServer processes registered
  in `Registry.Game`
  """
  @type via_tuple() :: {:via, Registry, {Registry.Game, String.t()}}

  @typedoc """
  Represents a game reference as either a PID or a `:via` tuple
  """
  @type game_reference() :: pid() | via_tuple()

  # Represents the call messages that can be sent to the game GenServer
  @typep call_messages() ::
           {:add_player, name :: String.t()}
           | {:position_island, Player.role(), Island.island_type(), row :: pos_integer(),
              column :: pos_integer()}
           | {:set_islands, Player.role()}
           | {:guess_coordinate, Player.role(), row :: pos_integer(), column :: pos_integer()}

  # Tests whether the given `term` is a game reference or not, which means testing whether
  # `term` is a PID or `:via` tuple
  defguard is_game_reference(term)
           when is_pid(term) or
                  (is_tuple(term) and elem(term, 0) == :via and elem(term, 1) == Registry and
                     is_tuple(elem(term, 2)) and
                     elem(elem(term, 2), 0) == :"Elixir.Registry.Game" and
                     is_binary(elem(elem(term, 2), 1)))

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
    GenServer.start_link(__MODULE__, name, name: create_via_tuple(name))
  end

  @doc """
  Given the player `name`, returns a `Registry` via tuple to be used for registering
  an islands game `GenServer` under `name`
  """
  @spec create_via_tuple(String.t()) :: via_tuple()
  def create_via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  @doc """
  Adds a second player to the game
  """
  @spec add_player(game_reference(), String.t()) :: :ok | :error
  def add_player(game_reference, name)
      when is_game_reference(game_reference) and is_binary(name) do
    GenServer.call(game_reference, {:add_player, name})
  end

  @doc """
  Positions a player's island
  """
  @spec position_island(
          game_reference(),
          Player.role(),
          Island.island_type(),
          pos_integer(),
          pos_integer()
        ) ::
          :ok
          | :error
          | {:error, :invalid_coordinate}
          | {:error, :invalid_island_type}
          | {:error, :overlapping_island}
  def position_island(game_reference, player_role, island_type, row, column)
      when is_game_reference(game_reference) and is_player_role(player_role) do
    GenServer.call(game_reference, {:position_island, player_role, island_type, row, column})
  end

  @doc """
  Sets a player's island positions
  """
  @spec set_islands(game_reference(), Player.role()) ::
          :ok | {:ok, Board.t()} | :error | {:error, :not_all_islands_positioned}
  def set_islands(game_reference, player_role)
      when is_game_reference(game_reference) and is_player_role(player_role) do
    GenServer.call(game_reference, {:set_islands, player_role})
  end

  @doc """
  Guesses a coordinate for the given player
  """
  @spec guess_coordinate(game_reference(), Player.role(), pos_integer(), pos_integer()) ::
          {:hit | :miss, Island.island_type(), :win | :no_win}
          | :error
          | {:error, :invalid_coordinate}
  def guess_coordinate(game_reference, player_role, row, column)
      when is_game_reference(game_reference) and is_player_role(player_role) do
    GenServer.call(game_reference, {:guess_coordinate, player_role, row, column})
  end

  @doc """
  Gets the timeout in milliseconds for waiting for new actions
  """
  @spec get_timeout_ms() :: timeout_ms()
  def get_timeout_ms(), do: @timeout_ms

  ########################################################################
  #### GenServer callbacks ###############################################
  ########################################################################

  @impl GenServer
  def init(name) do
    # Check if an existing game was stored in the game state ETS table. If so,
    # then grab its state. If not, use the fresh initialized game state.
    initial_state =
      case :ets.lookup(:game_state, name) do
        [] ->
          fresh_state = %__MODULE__{
            player1: Player.new(name),
            player2: Player.new(),
            rules: Rules.new()
          }

          # Create the game state
          :ets.insert(:game_state, {name, fresh_state})

          fresh_state

        [{^name, previous_state}] ->
          previous_state
      end

    {:ok, initial_state, @timeout_ms}
  end

  @impl GenServer
  @spec handle_call(call_messages(), {pid(), any()}, __MODULE__.t()) ::
          {:reply, __MODULE__.t(), __MODULE__.t(), timeout_ms()}
          | {:reply, :error, __MODULE__.t(), timeout_ms()}
          | {:reply, {:error, :not_all_islands_positioned}, __MODULE__.t(), timeout_ms()}
  def handle_call({:add_player, name}, _from, state) do
    case Rules.check(state.rules, :add_player) do
      {:ok, rules} ->
        state
        |> update_player2_name(name)
        |> update_rules(rules)
        |> reply_success(:ok)

      :error ->
        {:reply, :error, state, @timeout_ms}
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
        {:reply, check_error, state, @timeout_ms}

      {:error, :invalid_coordinate} = coordinate_new_error ->
        {:reply, coordinate_new_error, state, @timeout_ms}

      {:error, :invalid_island_type} = coordinate_or_island_new_error ->
        {:reply, coordinate_or_island_new_error, state, @timeout_ms}

      {:error, :overlapping_island} = position_island_error ->
        {:reply, position_island_error, state, @timeout_ms}
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
      :error -> {:reply, :error, state, @timeout_ms}
      false -> {:reply, {:error, :not_all_islands_positioned}, state, @timeout_ms}
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
        {:reply, rules_check_error, state, @timeout_ms}

      {:error, :invalid_coordinate} = coordinate_new_error ->
        {:reply, coordinate_new_error, state, @timeout_ms}
    end
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  @impl GenServer
  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player1.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok

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

  @spec reply_success(__MODULE__.t(), reply) :: {:reply, reply, __MODULE__.t(), pos_integer()}
        when reply: any()
  defp reply_success(state, reply) do
    # Update the game state ETS table with the new game state
    :ets.insert(:game_state, {state.player1.name, state})

    {:reply, reply, state, @timeout_ms}
  end

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
end

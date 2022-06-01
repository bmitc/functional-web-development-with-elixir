defmodule IslandsEngine.Rules do
  @moduledoc """
  Defines the state of an islands game and handles the state machine
  that processes actions for given states
  """

  defstruct state: :initialized,
            player1: :islands_not_set,
            player2: :islands_not_set

  @typedoc """
  Represents the state of an islands game
  """
  @type t() :: %__MODULE__{
          state: state(),
          player1: islands_set_state(),
          player2: islands_set_state()
        }

  @typedoc """
  Represents the state of an islands game
  """
  @type state() ::
          :initialized
          | :players_set
          | :player1_turn
          | :player2_turn
          | :game_over

  @typedoc """
  Represents an islands game player
  """
  @type player() ::
          :player1
          | :player2

  @typedoc """
  Represents an islands game action
  """
  @type action() ::
          :add_player
          | {:position_islands, player()}
          | {:set_islands, player()}
          | {:guess_coordinate, player()}
          | {:win_check, :win | :no_win}

  @typedoc """
  Represents whether all islands for a player have been set or not
  """
  @type islands_set_state() ::
          :islands_not_set
          | :islands_set

  @doc """
  Creates a new islands game state
  """
  @spec new() :: __MODULE__.t()
  def new(), do: %__MODULE__{}

  @doc """
  Checks whether the action is valid for the current state. If so, the action is
  processed and the state updated in a success tuple. Otherwise, an error is returned.
  """
  @spec check(__MODULE__.t(), action()) :: {:ok, __MODULE__.t()} | :error

  # Process adding a player
  def check(%__MODULE__{state: :initialized} = rules, :add_player) do
    {:ok, %__MODULE__{rules | state: :players_set}}
  end

  # Process a player positioning islands
  def check(%__MODULE__{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_not_set -> {:ok, rules}
      :islands_set -> :error
    end
  end

  # Process a player setting islands
  def check(%__MODULE__{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    if both_players_islands_set?(rules) do
      {:ok, %__MODULE__{rules | state: :player1_turn}}
    else
      {:ok, rules}
    end
  end

  # Process player1's guess and transition to player2's turn
  def check(%__MODULE__{state: :player1_turn} = rules, {:guess_coordinate, :player1}) do
    {:ok, %__MODULE__{rules | state: :player2_turn}}
  end

  # Process if the game is over during player1's turn
  def check(%__MODULE__{state: :player1_turn} = rules, {:win_check, win_or_not}) do
    check_if_game_over(rules, win_or_not)
  end

  # Process player2's guess and transition to player1's turn
  def check(%__MODULE__{state: :player2_turn} = rules, {:guess_coordinate, :player2}) do
    {:ok, %__MODULE__{rules | state: :player1_turn}}
  end

  # Process if the game is over during player2's turn
  def check(%__MODULE__{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    check_if_game_over(rules, win_or_not)
  end

  # Catch all for invalid actions
  def check(_rules, _action), do: :error

  # Checks if both players have set their islands' positions or not
  @spec both_players_islands_set?(__MODULE__.t()) :: boolean()
  defp both_players_islands_set?(rules) do
    rules.player1 == :islands_set && rules.player2 == :islands_set
  end

  # Checks if a game is over or not and returns the appropriate state,
  # transitioning to the game over state if the game is over and otherwise
  # staying in the same state
  @spec check_if_game_over(__MODULE__.t(), :win | :no_win) :: {:ok, __MODULE__.t()}
  defp check_if_game_over(rules, win_or_not) do
    case win_or_not do
      :win -> {:ok, %__MODULE__{rules | state: :game_over}}
      :no_win -> {:ok, rules}
    end
  end
end

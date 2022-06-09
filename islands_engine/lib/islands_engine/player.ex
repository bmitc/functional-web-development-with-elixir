defmodule IslandsEngine.Player do
  @moduledoc """
  Represents an islands game player
  """

  alias IslandsEngine.Board
  alias IslandsEngine.Guesses

  defstruct name: nil,
            board: Board.new(),
            guesses: Guesses.new()

  @typedoc """
  Represents an islands game player
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          board: Board.t(),
          guesses: Guesses.t()
        }

  @typedoc """
  Represents a player's role
  """
  @type role() :: :player1 | :player2

  @roles [:player1, :player2]

  @doc """
  Returns true if the term is a `Player.role`
  """
  defguard is_player_role(term) when term in @roles

  @doc """
  Creates a new islands game player
  """
  @spec new(String.t() | nil) :: __MODULE__.t()
  def new(name \\ nil), do: %__MODULE__{name: name}

  @doc """
  Updates the player's name
  """
  @spec update_name(__MODULE__.t(), String.t()) :: __MODULE__.t()
  def update_name(player, name), do: %__MODULE__{player | name: name}

  @doc """
  Returns a list of possible player roles
  """
  @spec roles() :: [role()]
  def roles(), do: @roles
end

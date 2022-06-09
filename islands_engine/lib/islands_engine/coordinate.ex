defmodule IslandsEngine.Coordinate do
  @moduledoc """
  Represents a coordinate on a board. Valid row and coordinate columns vary from 1 to 10, inclusive.
  """

  @enforce_keys [:row, :column]
  defstruct @enforce_keys

  @typedoc """
  Represents a coordiante
  """
  @type t() :: %__MODULE__{
          row: integer(),
          column: integer()
        }

  @board_range 1..10

  @doc """
  Checks if the given row and column are valid values
  """
  defguard is_valid_row_column(row, column) when row in @board_range and column in @board_range

  @doc """
  Creates a new coordinate. Rows and columns are restricted to the range [1, 10].
  """
  @spec new(pos_integer(), pos_integer()) :: {:ok, __MODULE__.t()} | {:error, :invalid_coordinate}
  def new(row, column) when is_valid_row_column(row, column) do
    {:ok, %__MODULE__{row: row, column: column}}
  end

  def new(_row, _column) do
    {:error, :invalid_coordinate}
  end
end

defmodule IslandsEngine.Guesses do
  @moduledoc """
  Represents guesses
  """

  alias IslandsEngine.Coordinate

  @enforce_keys [:hits, :misses]
  defstruct @enforce_keys

  @typedoc """
  Represents guesses
  """
  @type t() :: %__MODULE__{
          hits: MapSet.t(Coordinate.t()),
          misses: MapSet.t(Coordinate.t())
        }

  @doc """
  Creates a new guesses struct
  """
  @spec new() :: __MODULE__.t()
  def new() do
    %__MODULE__{hits: MapSet.new(), misses: MapSet.new()}
  end

  @doc """
  Adds a coordinate to the guesses depending on whether it's a `:hit` or `:miss`
  """
  @spec add(__MODULE__.t(), :hit | :miss, Coordinate.t()) :: __MODULE__.t()
  def add(%__MODULE__{} = guesses, :hit, %Coordinate{} = coordinate) do
    update_in(guesses.hits, &MapSet.put(&1, coordinate))
  end

  def add(%__MODULE__{} = guesses, :miss, %Coordinate{} = coordinate) do
    update_in(guesses.misses, &MapSet.put(&1, coordinate))
  end
end

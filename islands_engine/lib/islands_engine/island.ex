defmodule IslandsEngine.Island do
  @moduledoc """
  Represents an island
  """

  alias IslandsEngine.Coordinate

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct @enforce_keys

  @typedoc """
  Represents an island
  """
  @type t() :: %__MODULE__{
          coordinates: coordinates(),
          hit_coordinates: coordinates()
        }

  @typedoc """
  Represents all of the possible types of islands in an islands game
  """
  @type island_type :: :square | :atoll | :dot | :l_shape | :s_shape

  @typedoc """
  Represents a coordinate offset that can be used to offset a specific
  coordinate from some origin
  """
  @type offset :: {pos_integer(), pos_integer()}

  @typedoc """
  Represents a collection of coordinates, which is a `MapSet` consisting
  of elements of type `t()` to help when processing coordinates as opposed
  to a `list` or `map`
  """
  @type coordinates :: MapSet.t(Coordinate.t()) | MapSet.t()

  # Ignores the warning "Attempted to pattern match against the internal structure of an opaque term."
  # when pattern matching against `%MapSet{}` in `new/2`
  @dialyzer {:no_opaque, new: 2}

  @doc """
  Creates a new island
  """
  @spec new(island_type() | any(), Coordinate.t()) ::
          {:ok, __MODULE__.t()} | {:error, :invalid_island_type | :invalid_coordinate}
  def new(type, %Coordinate{} = upper_left) do
    with [{_, _} | _] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %__MODULE__{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    end
  end

  @doc """
  Tests whether two islands have overlapping coordinates or not
  """
  @spec overlaps?(__MODULE__.t(), __MODULE__.t()) :: boolean()
  def overlaps?(existing_island, new_island) do
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)
  end

  @doc """
  Compares two islands
  """
  @spec equal?(__MODULE__.t(), __MODULE__.t()) :: boolean()
  def equal?(
        %__MODULE__{coordinates: coordinates_1, hit_coordinates: hit_coordinates_1},
        %__MODULE__{coordinates: coordinates_2, hit_coordinates: hit_coordinates_2}
      ) do
    MapSet.equal?(coordinates_1, coordinates_2) and
      MapSet.equal?(hit_coordinates_1, hit_coordinates_2)
  end

  @doc """
  Determines whether a coordinate is a hit for a given island. If so, the island's
  hit coordinates are updated.
  """
  @spec guess(__MODULE__.t(), Coordinate.t()) :: {:hit, __MODULE__.t()} | :miss
  def guess(island, coordinate) do
    if MapSet.member?(island.coordinates, coordinate) do
      hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
      {:hit, %{island | hit_coordinates: hit_coordinates}}
    else
      :miss
    end
  end

  @doc """
  Determines whether an island is forested or not. An island is forested if all of its
  coordinates have been hit.
  """
  @spec forested?(__MODULE__.t()) :: boolean()
  def forested?(island) do
    MapSet.equal?(island.coordinates, island.hit_coordinates)
  end

  @doc """
  Returns a list of all the possible island types
  """
  @spec types() :: [island_type()]
  def types(), do: [:square, :atoll, :dot, :l_shape, :s_shape]

  @spec add_coordinates([offset()], Coordinate.t()) ::
          coordinates() | {:error, :invalid_coordinate}
  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn island_type, coordinates ->
      add_coordinate(coordinates, upper_left, island_type)
    end)
  end

  @spec add_coordinate(coordinates(), Coordinate.t(), offset()) ::
          {:cont, coordinates()} | {:halt, {:error, :invalid_coordinate}}
  defp add_coordinate(
         coordinates,
         %Coordinate{row: row, column: column},
         {row_offset, column_offset}
       ) do
    case Coordinate.new(row + row_offset, column + column_offset) do
      {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
      {:error, :invalid_coordinate} = error -> {:halt, error}
    end
  end

  # Generates a list of offsets for the given island type
  @spec offsets(island_type | any()) :: [offset()] | {:error, :invalid_island_type}
  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]

  defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]

  defp offsets(:dot), do: [{0, 0}]

  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]

  defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]

  defp offsets(_), do: {:error, :invalid_island_type}
end

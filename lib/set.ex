defmodule Exa.Set do
  @moduledoc "Set utilities."

  import Exa.Types

  @doc "Update a set with a collection of new entries."
  @spec adds(MapSet.t(), Enumerable.t()) :: MapSet.t()
  def adds(set, coll) when is_set(set) do
    Enum.reduce(coll, set, &MapSet.put(&2, &1))
  end

  @doc """
  Get the minimum value in a set
  according to the Elixir term ordering.
  Return error if the set is empty.

  ## Examples

      iex> min( MapSet.new([1,2,3,4]) )
      1
      iex> min( MapSet.new() )
      {:error, "Empty set"}
  """
  @spec min(MapSet.t()) :: any() | {:error, any()}
  def min(ms) when is_set(ms) do
    Enum.min(ms, fn -> {:error, "Empty set"} end)
  end

  @doc """
  Get the maximum value in a set
  according to the Erlang term ordering.
  Return error if the set is empty.

  ## Examples

      iex> max( MapSet.new([1,2,3,4]) )
      4

      iex> max( MapSet.new() )
      {:error, "Empty set"}
  """
  @spec max(MapSet.t()) :: any() | {:error, any()}
  def max(ms) when is_set(ms) do
    Enum.max(ms, fn -> {:error, "Empty set"} end)
  end

  @doc """
  Sum values in a set.
  Return error if the set is empty 
  or contains non-numeric data.

  ## Examples

      iex> sum( MapSet.new([1,2,3,4]) )
      10
      iex> sum( MapSet.new() )
      {:error, "Empty set"}
      iex> sum( MapSet.new([:foo]) )
      {:error, %ArithmeticError{
         message: "bad argument in arithmetic expression"
      }}
  """
  @spec sum(MapSet.t()) :: number() | {:error, any()}
  def sum(ms) when is_set(ms) do
    if MapSet.size(ms) == 0 do
      {:error, "Empty set"}
    else
      Enum.sum(ms)
    end
  rescue
    err -> {:error, err}
  end

  @doc """
  Multiply values in a set.
  Return error if the set is empty 
  or contains non-numeric data.

  ## Examples

      iex> product( MapSet.new([1,2,3,4]) )
      24
      iex> product( MapSet.new() )
      {:error, "Empty set"}
      iex> product( MapSet.new([:foo]) )
      {:error, %ArithmeticError{
         message: "bad argument in arithmetic expression"
      }}
  """
  @spec product(MapSet.t()) :: number() | {:error, any()}
  def product(ms) when is_set(ms) do
    if MapSet.size(ms) == 0 do
      {:error, "Empty set"}
    else
      Enum.product(ms)
    end
  rescue
    err -> {:error, err}
  end

  @doc """
  Pick one element from a set.

  Return the element and the remaining set
  with the element removed.

  If the set is empty, return error.

  Assume the Axiom of Choice :)

  ## Examples

      iex> pick( MapSet.new([1,2,3,4]) )
      {1, MapSet.new([2,3,4])}

      iex> pick( MapSet.new() )
      {:error, "Empty set"}
  """
  @spec pick(MapSet.t()) :: {any(), MapSet.t()} | {:error, any()}
  def pick(ms) do
    if MapSet.size(ms) == 0 do
      {:error, "Empty set"}
    else
      [x] = Enum.take(ms, 1)
      {x, MapSet.delete(ms, x)}
    end
  end

  @doc """
  Apply a mapping over a set and return a set.

  The mapping must have values for every member of the set.

  Equivalent to `ms |> MapSet.to_list() |> MapSet.new()`
  but in one pass, without the intermediate list.

  ## Examples

      iex> map( MapSet.new(["foo", "bar", "baz"]), &String.first/1 )
      MapSet.new(["f","b"])

      iex> map( MapSet.new([1, 2, 3]), %{1 => 7, 2 => 8, 3 => 9} )
  """
  @spec map(MapSet.t(), E.mapping(any(), any())) :: MapSet.t()

  def map(ms, mapr) when is_set(ms) and is_mapper(mapr) do
    Enum.reduce(ms, MapSet.new(), fn x, out -> 
      MapSet.put(out, mapr.(x)) 
    end)
  end

  def map(ms, map) when is_set(ms) and is_map(map) do
    Enum.reduce(ms, MapSet.new(), fn x, out when is_map_key(map,x) -> 
      MapSet.put(out, map[x]) 
    end)
  end
end

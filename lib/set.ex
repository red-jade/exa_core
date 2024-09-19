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

      iex> Exa.Set.min( MapSet.new([1,2,3,4]) )
      1
      iex> Exa.Set.min( MapSet.new() )
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

      iex> Exa.Set.max( MapSet.new([1,2,3,4]) )
      4

      iex> Exa.Set.max( MapSet.new() )
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

      iex> Exa.Set.sum( MapSet.new([1,2,3,4]) )
      10
      iex> Exa.Set.sum( MapSet.new() )
      {:error, "Empty set"}
      iex> Exa.Set.sum( MapSet.new([:foo]) )
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

      iex> Exa.Set.product( MapSet.new([1,2,3,4]) )
      24
      iex> Exa.Set.product( MapSet.new() )
      {:error, "Empty set"}
      iex> Exa.Set.product( MapSet.new([:foo]) )
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

      iex> Exa.Set.pick( MapSet.new([1,2,3,4]) )
      {1, MapSet.new([2,3,4])}

      iex> Exa.Set.pick( MapSet.new() )
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
  Map a function over a set and return a set.

  ## Examples

      iex> Exa.Set.map( MapSet.new(["foo", "bar", "baz"]), &String.first/1 )
      MapSet.new(["f","b"])
  """
  @spec map(MapSet.t(), E.mapper(any(), any())) :: MapSet.t()
  def map(ms, mapr) do
    Enum.reduce(ms, MapSet.new(), fn x, out -> MapSet.put(out, mapr.(x)) end)
  end
end

defmodule Exa.Map do
  @moduledoc """
  Map utilities.

  Also see `Exa.Std.Mol` module.
  """

  import Exa.Types
  alias Exa.Types, as: E

  @doc """
  Zip two lists of the same size to build a map.

  Equivalent to `xs |> Enum.zip(ys) |> Map.new()`
  but in a single pass.

  ## Examples:
      iex> zip_new([1, 2], [:foo, :bar])
      %{1 => :foo, 2 => :bar}
  """
  @spec zip_new([a], [b]) :: %{a => b} when a: var, b: var
  def zip_new(xs, ys) when is_list(xs) and is_list(ys), do: do_zip(xs, ys, %{})

  @spec do_zip([a], [b], %{a => b}) :: %{a => b} when a: var, b: var
  defp do_zip([x | xs], [y | ys], m), do: do_zip(xs, ys, Map.put(m, x, y))
  defp do_zip([], [], m), do: m

  @doc """
  Map a function over the values of a map.

  ## Examples:
      iex> map( %{1 => [1,2,3], 2 => [], 3 => [2,1]}, &length/1)
      %{1 => 3, 2 => 0, 3 => 2}
  """
  @spec map(%{a => b}, E.mapper(b, c)) :: %{a => c} when a: var, b: var, c: var
  def map(map, fun) when is_map(map) and is_mapper(fun) do
    map |> Map.keys() |> Enum.reduce(map, fn k, m -> Map.update!(m, k, fun) end)
  end

  @doc """
  Invert a general map. 

  Accumulate a unsorted list of keys that map to the same value.

  ## Examples:
      iex> invert(%{})
      %{}
      iex> invert( %{1 => 2, 2 => 3, 3 => 1, 4 => 2} )
      %{1 => [3], 2 => [4,1], 3 => [2]}
  """
  @spec invert(%{a => b}) :: %{b => [a, ...]} when a: var, b: var
  def invert(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, m ->
      Map.update(m, v, [k], fn ks -> [k | ks] end)
    end)
  end

  @doc """
  Invert a bijective map (1-1 and onto).

  Raises error if the map is not bijective,
  i.e. there is more than one key that maps to the same value.

  ## Examples

     iex> invert!( %{1 => 2, 2 => 3, 3 => 1, 4 => 4} )
     %{1 => 3, 2 => 1, 3 => 2, 4 => 4}
  """
  @spec invert!(%{a => b}) :: %{b => a} when a: var, b: var
  def invert!(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {_, v}, m when is_map_key(m, v) ->
        raise RuntimeError,
          message: "Not bijective, duplicate value #{v}, map:\n#{inspect(map)}"

      {k, v}, m ->
        Map.put(m, v, k)
    end)
  end

  @doc """
  Inverse look-up: get the key for a value.

  It is assumed that the map is bijective.
  If more than one copy of the value exists, 
  only the first key to be found is returned.
  That choice of key is arbitrary.

  If the value does not exist, 
  then return a default key or `nil` (default)

  ## Examples

      iex> key( %{1 => 2, 2 => 3, 3 => 2, 4 => 4}, 3 )
      2
      iex> key( %{1 => 2, 2 => 3, 3 => 2, 4 => 4}, 2 )
      1
      iex> key( %{1 => 2, 2 => 3, 3 => 2, 4 => 4}, 99 )
      nil
  """
  @spec key(%{a => b}, b, a | nil) :: E.maybe(a) when a: var, b: var
  def key(map, v, default \\ nil) do
    Enum.reduce_while(Map.keys(map), nil, fn k, nil ->
      case Map.fetch!(map, k) do
        ^v -> {:halt, k}
        _ -> {:cont, default}
      end
    end)
  end

  @doc """
  Inverse look-up: get all keys for a value.

  If the value does not exist, 
  then return the empty list.

  ## Examples

      iex> keys( %{1 => 2, 2 => 3, 3 => 2, 4 => 4}, 3 )
      [2]
      iex> keys( %{1 => 2, 2 => 3, 3 => 2, 4 => 4}, 2 ) |> Enum.sort()
      [1, 3]
      iex> keys( %{1 => 2, 2 => 3, 3 => 1, 4 => 4}, 99 )
      []
  """
  @spec keys(%{a => b}, b) :: [a] when a: var, b: var
  def keys(map, v) do
    Enum.reduce(map, [], fn
      {k, ^v}, keys -> [k | keys]
      _, keys -> keys
    end)
  end

  @doc """
  Pick one entry from a map.

  Return the key-value pair, 
  and the remaining map with the key removed.

  If the map is empty, return error.

  Assume the Axiom of Choice :)

  ## Examples

      iex> pick( %{1 => 2, 2 => 3, 3 => 2} )
      {{1, 2}, %{2 => 3, 3 => 2}}

      iex> pick( %{} )
      {:error, "Empty map"}
  """
  @spec pick(map()) :: {{any(), any()}, map()} | {:error, any()}
  def pick(m) do
    if map_size(m) == 0 do
      {:error, "Empty map"}
    else
      [{k, _} = entry] = Enum.take(m, 1)
      {entry, Map.delete(m, k)}
    end
  end
end

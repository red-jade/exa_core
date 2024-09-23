defmodule Exa.Factory do
  @moduledoc """
  A factory factory for structs and maps.

  A factory takes a keyword list (key-value tuples),
  finds the struct that has the best match of keys,
  then returns a new struct containing the keyword data.
  If no struct matches keys, then a simple map is returned.

  This module is a factory for the factory method.
  """

  import Exa.Types

  @type factory_fun() :: (Keyword.t() -> {:struct, struct()} | {:map, map()})

  @doc "Get the sorted list of keys of a struct."
  @spec struct_keys(module()) :: [atom()]
  def struct_keys(mod) when is_module(mod) do
    mod.__struct__() |> Map.keys() |> List.delete(:__struct__) |> Enum.sort()
  end

  @doc """
  Generate the factory.

  Take a list of struct modules, return a factory method,
  which builds a struct from a keyword list.
  Raises an error if two of the structs contain the same set of keys.
  """
  @spec factory([module()]) :: factory_fun()
  def factory(mods) when is_list_nonempty(mods) and is_module(hd(mods)) do
    index =
      Enum.reduce(mods, %{}, fn m, index ->
        # use MapSet or sorted atom list?
        # MapSet will support subset matching later
        k = m |> struct_keys()
        # |> MapSet.new()

        if Map.has_key?(index, k) do
          raise ArgumentError, message: "Duplicate set of keys: #{struct_keys(m)}"
        end

        Map.put(index, k, fn kw -> struct(m, kw) end)
      end)

    # use key equality, so kw must be complete - no omitted optional fields
    # TODO - search for largest subset of keys for best-match struct?

    fn kw ->
      k = kw |> Keyword.keys()
      # |> MapSet.new()

      if Map.has_key?(index, k) do
        {:struct, Map.fetch!(index, k).(kw)}
      else
        {:map, Map.new(kw)}
      end
    end
  end
end

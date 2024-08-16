defmodule Exa.Set do
  @moduledoc "Set utilities."

  import Exa.Types

  @doc "Update a set with a collection of new entries."
  @spec adds(MapSet.t(), Enumerable.t()) :: MapSet.t()
  def adds(set, coll) when is_set(set) do
    Enum.reduce(coll, set, &MapSet.put(&2, &1))
  end

  @doc "Get the minimum value in a set."
  @spec min(MapSet.t()) :: any()
  def min(ms) when is_set(ms) do
    Enum.reduce(ms, &Kernel.min/2)
  end

  @doc "Get the maximum value in a set."
  @spec max(MapSet.t()) :: any()
  def max(ms) when is_set(ms) do
    Enum.reduce(ms, &Kernel.max/2)
  end

  @doc "Sum values in a set."
  @spec sum(MapSet.t()) :: any()
  def sum(ms) when is_set(ms) do
    Enum.reduce(ms, &Kernel.+/2)
  end
end

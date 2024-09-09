defmodule Exa.Set do
  @moduledoc "Set utilities."

  import Exa.Types

  @doc "Update a set with a collection of new entries."
  @spec adds(MapSet.t(), Enumerable.t()) :: MapSet.t()
  def adds(set, coll) when is_set(set) do
    Enum.reduce(coll, set, &MapSet.put(&2, &1))
  end

  @doc """
  Get the minimum value in a set,
  or error if the set is empty.
  """
  @spec min(MapSet.t()) :: any() | {:error, any()}
  def min(ms) when is_set(ms) do
    if MapSet.size(ms) == 0, do: :error, else: Enum.reduce(ms, &Kernel.min/2)
  rescue
    err -> {:error, err}
  end

  @doc """
  Get the maximum value in a set.
  Return error if the set is empty or contains non-numerica data.
  """
  @spec max(MapSet.t()) :: any() | {:error, any()}
  def max(ms) when is_set(ms) do
    if MapSet.size(ms) == 0 do
      {:error, "Empty set"}
    else
      Enum.reduce(ms, &Kernel.max/2)
    end
  rescue
    err -> {:error, err}
  end

  @doc """
  Sum values in a set.
  Return error if the set is empty or contains non-numerica data.
  """
  @spec sum(MapSet.t()) :: any() | :error
  def sum(ms) when is_set(ms) do
    if MapSet.size(ms) == 0 do
      {:error, "Empty set"}
    else
      Enum.reduce(ms, &Kernel.+/2)
    end
  rescue
    err -> {:error, err}
  end
end

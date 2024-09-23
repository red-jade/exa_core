defmodule Exa.Random do
  @moduledoc "Random utilities."

  import Exa.Types

  @doc "Create a random integer between 1 and N."
  @spec rndint(pos_integer()) :: pos_integer()
  def rndint(n) when is_integer(n) and n > 0, do: :rand.uniform(n)

  @doc """
  Create a random number between 1 and N,
  excluding a specific value to be avoided.
  """
  @spec rndint(pos_integer(), pos_integer()) :: pos_integer()
  def rndint(n, avoid) when is_int_pos(n) and is_in_range(1, avoid, n) do
    case rndint(n) do
      ^avoid -> rndint(n, avoid)
      i -> i
    end
  end
end

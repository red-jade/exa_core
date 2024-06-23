defmodule Exa.Random do
  @moduledoc "Random utilities."

  @doc "Create a random integer between 1 and N."
  @spec rndint(pos_integer()) :: pos_integer()
  def rndint(n) when is_integer(n) and n > 0, do: :rand.uniform(n)

  @doc """
  Create a random number between 1 and N,
  excluding a specific value to be avoided.
  """
  @spec rndint(pos_integer(), pos_integer()) :: pos_integer()
  def rndint(n, avoid)
      when is_integer(n) and n > 1 and
             is_integer(avoid) and avoid >= 1 and avoid <= n do
    case rndint(n) do
      ^avoid -> rndint(n, avoid)
      i -> i
    end
  end
end

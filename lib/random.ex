defmodule Exa.Random do
  @moduledoc """
  Utilities for random values.

  Provide uniform random values for: 
  boolean, bit, binary, integer and float.

  Provide normally distributed float values.

  A thin wrapper around the Erlang `:rand` module.
  """
  import Bitwise

  import Exa.Types

  @doc """
  Create a random boolean value from a uniform distribution.
  """
  @spec uniform_bool?() :: bool()
  def uniform_bool?(), do: :rand.uniform(256) > 128

  @doc """
  Create a random bit value from a uniform distribution.
  """
  @spec uniform_bit() :: 0 | 1
  def uniform_bit(), do: :rand.uniform(256) &&& 0x01

  @doc """
  Create a random binary containing _n_ random bytes.
  """
  @spec bytes(non_neg_integer()) :: binary()
  def bytes(n) when is_int_nonneg(n), do: :rand.bytes(n)

  @doc "Create a random integer between 1 and _n_ inclusive."
  @spec uniform_int(pos_integer()) :: pos_integer()
  def uniform_int(n) when is_int_pos(n), do: :rand.uniform(n)

  @doc "Create a random integer between _m_ and _n_ inclusive."
  @spec uniform_int(integer(), integer()) :: integer()
  def uniform_int(m,n) when is_range(m,n) do 
    m1 = m - 1
    m1 + :rand.uniform(n - m1)
  end

  @doc """
  Create a random number between 1 and _n_ inclusive,
  but excluding a specific value to be avoided.
  """
  @spec uniform_intex(pos_integer(), pos_integer()) :: pos_integer()
  def uniform_intex(n, avoid) when is_int_pos(n) and is_in_range(1, avoid, n) do
    case uniform_int(n) do
      ^avoid -> uniform_int(n, avoid)
      i -> i
    end
  end

  @doc """
  Create a random float value `0.0 <= x < 1.0` from a uniform distribution.

  Note the value may be `0.0`, but is never `1.0`.
  """
  @spec uniform_float0() :: float()
  def uniform_float0(), do: :rand.uniform()

  @doc """
  Create a random float value `0.0 < x < 1.0` from a uniform distribution.

  Note the value will never be `0.0` or `1.0`.
  """
  @spec uniform_float() :: float()
  def uniform_float(), do: :rand.uniform_real()

  @doc """
  Create a random float value from a standard normal distribution
  (mean `0.0`, variance `1.0`).
  """
  @spec normal_float() :: float()
  def normal_float(), do: :rand.normal()
  
  @doc """
  Create a random float value from a normal distribution,
  with the specified mean and variance.
  """
  @spec normal_float(mean :: float(), variance :: E.non_neg_float()) :: float()
  def normal_float(u, v) when is_float(u) and is_zero(v), do: u
  def normal_float(u, v) when is_float(u) and is_float_pos(v), do: :rand.normal(u, v)
end

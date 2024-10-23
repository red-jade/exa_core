defmodule Exa.Stats do
  @moduledoc "Statistical utilities."

  import Exa.Types

  @doc """
  Count and mean of a non-empty list of numbers.

  ## Examples
      iex> n_mean([1,2,3])
      {3, 2.0}
  """
  @spec n_mean([number(), ...]) :: {n :: E.count1(), mean :: float()}
  def n_mean(xs) when is_list_nonempty(xs) do
    {n, s} = len_sum(xs, 0, 0)
    {n, s / n}
  end

  @doc """
  Count, mean and variance of a non-empty list of numbers.

  ## Examples
      iex> n_mean_var([1,2,3])
      {3, 2.0, 2/3}
  """
  @spec n_mean_var([number(), ...]) :: {n :: E.count1(), mean :: float(), variance :: float()}
  def n_mean_var(xs) when is_list_nonempty(xs) do
    {n, s} = len_sum(xs, 0, 0)
    u = s / n
    {n, u, do_sumsqd(xs, u, 0) / n}
  end

  @doc """
  Count, mean and standard deviation of a non-empty list of numbers.

  ## Examples
      iex> n_mean_var([1,2,3])
      {3, 2.0, 2/3}
  """
  @spec n_mean_sd([number(), ...]) :: {n :: E.count1(), mean :: float(), sd :: float()}
  def n_mean_sd(xs) when is_list_nonempty(xs) do
    {n, s} = len_sum(xs, 0, 0)
    u = s / n
    {n, u, :math.sqrt(do_sumsqd(xs, u, 0) / n)}
  end

  @doc """
  Count and Root Mean Square (RMS) of a non-empty list of numbers.

  ## Examples
      iex> n_rms([1,2,3])
      {3, 2.160246899469287}
  """
  @spec n_rms([number(), ...]) :: {n :: E.count1(), rms :: float()}
  def n_rms(xs) when is_list_nonempty(xs) do
    {n, sq} = len_sumsq(xs, 0, 0)
    {n, :math.sqrt(sq / n)}
  end

  @doc """
  Get the mode(s) of a non-empty list.

  Return the maximum frequency count
  and a list of all entries with that count.

  ## Examples
      iex> mode([1,2,3,2,1,1])
      {3, [1]}
      iex> mode([1,2,3,2,1])
      {2, [2,1]}
      iex> mode([1])
      {1, [1]}
  """
  @spec mode([any()]) :: {count :: E.count1(), modes :: [any()]}

  def mode([_] = is), do: {1, is}

  def mode(is) when is_list_nonempty(is) do
    is |> Enum.frequencies() |> Enum.reduce({0, []}, &max_freq/2)
  end

  # -----------------
  # private functions
  # -----------------

  # sum of square of differences to mean
  @spec do_sumsqd([number()], float(), float()) :: number()
  defp do_sumsqd([x | xs], u, sq), do: do_sumsqd(xs, u, sq + sq(x - u))
  defp do_sumsqd([], _u, sq), do: sq

  # length and sum of squares in a single pass
  @spec len_sumsq([number()], non_neg_integer(), float()) :: {non_neg_integer(), number()}
  defp len_sumsq([x | xs], n, sq), do: len_sumsq(xs, n + 1, sq + sq(x))
  defp len_sumsq([], n, sq), do: {n, sq}

  # length and sum in a single pass
  @spec len_sum([number()], non_neg_integer(), number()) :: {non_neg_integer(), number()}
  defp len_sum([x | xs], n, s), do: len_sum(xs, n + 1, s + x)
  defp len_sum([], n, s), do: {n, s}

  # reducer to find max count values from frequencies
  @spec max_freq({any(), E.count1()}, {E.count(), [any()]}) :: {E.count1(), [any()]}
  defp max_freq({i, n}, {nmax, _is}) when n > nmax, do: {n, [i]}
  defp max_freq({i, nmax}, {nmax, is}), do: {nmax, [i | is]}
  defp max_freq(_, acc), do: acc

  # square a number
  @spec sq(number()) :: number()
  defp sq(x), do: x * x
end

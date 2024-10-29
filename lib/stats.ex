defmodule Exa.Stats do
  @moduledoc """
  Statistical utilities.

  Also see `Exa.Std.Histo1D` and other histograms.
  """

  import Exa.Types
  alias Exa.Types, as: E

  @doc """
  Mean of a non-empty list of numbers.

  ## Examples
      iex> mean([1,2,3])
      2.0
  """
  @spec mean([number()]) :: float()
  def mean(xs) when is_list_nonempty(xs), do: Enum.sum(xs) / length(xs)

  @doc """
  Mean and variance of a non-empty list of numbers.

  ## Examples
      iex> mean_var([1,2,3])
      {2.0, 2/3}
  """
  @spec mean_var([number(), ...]) :: {mean :: float(), variance :: float()}
  def mean_var(xs) when is_list_nonempty(xs) do
    {n, u} = n_mean(xs)
    {u, sumsqd(xs, u) / n}
  end

  @doc """
  Variance of a non-empty list of numbers, given the mean.

  ## Examples
      iex> var([1,2,3], 2.0)
      2/3
  """
  @spec var([number(), ...], float()) :: float()
  def var(xs, u) when is_list_nonempty(xs) and is_float(u) do
    do_var(xs, u)
  end

  @doc """
  Mean and standard deviation of a non-empty list of numbers.

  ## Examples
      iex> mean_sd([1,2,3])
      {2.0, Exa.Math.sqrt(2/3)}
  """
  @spec mean_sd([number(), ...]) :: {mean :: float(), sd :: float()}
  def mean_sd(xs) when is_list_nonempty(xs) do
    {n, u} = n_mean(xs)
    {u, Exa.Math.sqrt(sumsqd(xs, u) / n)}
  end

  @doc """
  Standard deviation of a non-empty list of numbers,
  given the mean.

  ## Examples
      iex> sd([4,5,6], 5.0)
      Exa.Math.sqrt(2/3)
  """
  @spec sd([number(), ...], float()) :: float()
  def sd(xs, u) when is_list_nonempty(xs) and is_float(u) do
    Exa.Math.sqrt(var(xs, u))
  end

  @doc """
  Root Mean Square (RMS) of a non-empty list of numbers.

  ## Examples
      iex> rms([4,4,7])
      3 * Exa.Math.sqrt(3)
  """
  @spec rms([number(), ...]) :: float()
  def rms(xs) when is_list_nonempty(xs), do: do_rms(xs)

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
  @spec mode([t, ...]) :: {count :: E.count1(), modes :: [t]} when t: var

  def mode([_] = is), do: {1, is}

  def mode(is) when is_list_nonempty(is) do
    is |> Enum.frequencies() |> Enum.reduce({0, []}, &max_freq/2)
  end

  @doc """
  Get the median(s) of a non-empty list.

  The list is sorted, then the median depends on the length of the list:
  - odd: central value in the sorted list (element at `div(n,2)`)
  - even: the two central values (elements `n/2, n/2 + 1`)

  In the case of an even number of number values,
  the client may choose to average the two central values. 

  For even number of values, if the two central values are equal,
  then only one is returned.

  ## Examples:
      iex> median([1,2,3,4,5])
      3
      iex> median([6,5,4,3,2,1])
      {3,4}
      iex> median([4,2,2,1])
      2
      iex> median([:foo, :bar, :baz])
      :baz
      iex> median([10,9])
      {9,10}
  """
  @spec median([t, ...]) :: t | {t, t} when t: var
  def median([x]), do: x
  def median([x, y]) when x < y, do: {x, y}
  def median([x, x]), do: x
  def median([x, y]), do: {y, x}
  def median(xs) when is_list_nonempty(xs), do: do_med(length(xs), Enum.sort(xs))

  # -----------------
  # private functions
  # -----------------

  # sum of square of differences to mean
  @spec sumsqd([number(), ...], float(), float()) :: float()
  defp sumsqd(xs, u, sq \\ 0.0)
  defp sumsqd([x | xs], u, sq), do: sumsqd(xs, u, sq + sq(x - u))
  defp sumsqd([], _u, sq), do: sq

  # variance - average sum of square of differences to mean
  @spec do_var([number(), ...], float(), {non_neg_integer(), float()}) :: float()
  defp do_var(xs, u, n_sq \\ {0, 0.0})
  defp do_var([x | xs], u, {n, sq}), do: do_var(xs, u, {n + 1, sq + sq(x - u)})
  defp do_var([], _u, {n, sq}), do: sq / n

  # root mean square in a single pass
  @spec do_rms([number(), ...], non_neg_integer(), float()) :: float()
  defp do_rms(xs, n \\ 0, sq \\ 0.0)
  defp do_rms([x | xs], n, sq), do: do_rms(xs, n + 1, sq + sq(x))
  defp do_rms([], n, sq), do: Exa.Math.sqrt(sq / n)

  # count and mean in a single pass
  @spec n_mean([number(), ...], non_neg_integer(), float()) :: {non_neg_integer(), float()}
  defp n_mean(xs, n \\ 0, s \\ 0.0)
  defp n_mean([x | xs], n, s), do: n_mean(xs, n + 1, s + x)
  defp n_mean([], n, s), do: {n, s / n}

  # reducer to find max count values from frequencies
  @spec max_freq({any(), E.count1()}, {E.count(), [any()]}) :: {E.count1(), [any()]}
  defp max_freq({i, n}, {nmax, _is}) when n > nmax, do: {n, [i]}
  defp max_freq({i, nmax}, {nmax, is}), do: {nmax, [i | is]}
  defp max_freq(_, acc), do: acc

  # get median from count and sorted list
  @spec do_med(E.count1(), [t]) :: t | {t, t} when t: var
  defp do_med(n, s) when is_int_odd(n), do: Enum.at(s, div(n, 2))

  defp do_med(n, s) do
    case Enum.drop(s, div(n, 2) - 1) do
      [x, x | _] -> x
      [x, y | _] -> {x, y}
    end
  end

  # square a number
  @spec sq(number()) :: number()
  defp sq(x), do: x * x
end

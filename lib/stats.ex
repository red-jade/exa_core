defmodule Exa.Stats do
  @moduledoc """
  Statistical utilities.

  Also see `Exa.Std.Histo1D` and other histograms.
  """

  import Exa.Types
  alias Exa.Types, as: E

  # -----------
  # local types
  # -----------

  @typedoc "A non-empty list of numbers."
  @type data1D() :: [x :: number(), ...]

  defguard is_data1d(xs) when is_list_nonempty(xs) and is_number(hd(xs))

  @typedoc "A non-empty list of pairs of numbers."
  @type data2D() :: [{x :: number(), y :: number()}, ...]

  defguard is_data2d(xys) when is_list_nonempty(xys) and is_tuple(hd(xys))

  # ----------------
  # puvbic functions
  # ----------------

  @doc """
  Mean of a non-empty list of numbers.

  `μ = Σx / n`

  ## Examples
      iex> mean([1,2,3])
      2.0
  """
  @spec mean(data1D()) :: float()
  def mean(xs) when is_data1d(xs), do: Enum.sum(xs) / length(xs)

  @doc """
  Mean and variance of a non-empty list of numbers.

  ```
  μ = Σx / n
  σ = Σ(x-μ)² / n
  ```

  ## Examples
      iex> mean_var([1,2,3])
      {2.0, 2/3}
  """
  @spec mean_var(data1D()) :: {mean :: float(), variance :: float()}
  def mean_var(xs) when is_data1d(xs) do
    {n, u} = n_mean(xs)
    {u, sumsqd(xs, u) / n}
  end

  @doc """
  Variance of a non-empty list of numbers, given the mean.

  `σ = Σ(x-μ)² / n`

  ## Examples
      iex> var([1,2,3], 2.0)
      2/3
  """
  @spec var(data1D(), float()) :: float()
  def var(xs, u) when is_data1d(xs) and is_float(u) do
    do_var(xs, u)
  end

  @doc """
  Mean and standard deviation of a non-empty list of numbers.

  ```
  μ = Σx / n
  s.d. = √( Σ(x-μ)² / n )`
  ```

  ## Examples
      iex> mean_sd([1,2,3])
      {2.0, Exa.Math.sqrt(2/3)}
  """
  @spec mean_sd(data1D()) :: {mean :: float(), sd :: float()}
  def mean_sd(xs) when is_data1d(xs) do
    {n, u} = n_mean(xs)
    {u, Exa.Math.sqrt(sumsqd(xs, u) / n)}
  end

  @doc """
  Standard deviation of a non-empty list of numbers,
  given the mean.

  The standard deviation is the square root of the variance:

  `s.d. = √σ = √( Σ(x-μ)² / n )`

  ## Examples
      iex> sd([4,5,6], 5.0)
      Exa.Math.sqrt(2/3)
  """
  @spec sd(data1D(), float()) :: float()
  def sd(xs, u) when is_data1d(xs) and is_float(u) do
    Exa.Math.sqrt(var(xs, u))
  end

  @doc """
  Root Mean Square (RMS) of a non-empty list of numbers.

  `rms = √( Σx² / n )`

  ## Examples
      iex> rms([4,4,7])
      3 * Exa.Math.sqrt(3)
  """
  @spec rms(data1D()) :: float()
  def rms(xs) when is_data1d(xs), do: do_rms(xs)

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

  @doc """
  Linear regression of a non-empty 2D dataset.

  Fit a straight line to set of `{x,y}` points.

  The line is given by `y = a + bx`, 
  where `a` is the intercept on the y-axis,
  and `b` is the gradient (slope).

  Also return `r²`, the square of the Pearson correlation coefficient.

  ```
  a =  [ (Σy)(Σx²) - (Σx)(Σxy) ]  / [  n(Σx²) - (Σx)² ]` 
  b =  [  n(Σxy)   - (Σx)(Σy)  ]  / [  n(Σx²) - (Σx)² ]` 

  r² = [  n(Σxy)   – (Σx)(Σy)  ]² / [ (n(Σx²) - (Σx)²) * (n(Σy²)-(Σy)²) ]
  ```

  ## Examples:
      iex> regression_linear([{3,8},{9,6},{5,4},{3,2}])
      {400/96, 16/96, 1/30}
  """
  @spec regression_linear(data2D()) ::
          {intercept :: float(), gradient :: float(), rsquared :: float()}
  def regression_linear(xys) when is_data2d(xys) do
    {n, sx, sy, sxx, syy, sxy} =
      Enum.reduce(
        xys,
        {0, 0.0, 0.0, 0.0, 0.0, 0.0},
        fn {x, y}, {n, sx, sy, sxx, syy, sxy} ->
          {n + 1, sx + x, sy + y, sxx + x * x, syy + y * y, sxy + x * y}
        end
      )

    dx = n * sxx - sx * sx
    dy = n * syy - sy * sy
    a = sy * sxx - sx * sxy
    b = n * sxy - sx * sy
    {a / dx, b / dx, b * b / (dx * dy)}
  end

  @doc """
  Calculate the Pearson correlation cofficient _r_ for a non-empty 2D dataset.

  The Pearson coefficient is defined as: 

  `r = covariance(xy) / (sd(x) * sd(y))`

  ## Examples: 
      iex> pearson([{3,8},{9,6},{5,4},{3,2}])
      Exa.Math.sqrt(1/30)
  """
  @spec pearson(data2D()) :: float()
  def pearson(xys) when is_data2d(xys) do
    {ux, sdx} = xys |> Enum.map(&elem(&1, 0)) |> mean_sd()
    {uy, sdy} = xys |> Enum.map(&elem(&1, 1)) |> mean_sd()
    covar(xys, ux, uy) / (sdx * sdy)
  end

  @doc """
  Covariance of a non-empty 2D dataset, 
  given the means of the separate coordinates.

  The covariance is the average of the product of 
  each coordinate's difference to its mean:

  `covariance = Σ[(x-μx)*(y-μy)] / n`

  ## Examples: 
      iex> covar([{3,8},{9,6},{5,4},{3,2}], 5.0, 5.0)
      1.0
  """
  @spec covar(data2D(), number(), number()) :: float()
  def covar(xys, ux, uy) when is_data2d(xys) and is_number(ux) and is_number(uy) do
    do_covar(xys, ux, uy)
  end

  @doc """
  Covariance of a non-empty 2D dataset.

  `covariance = Σ[(x-μx)*(y-μy)] / n`

  ## Examples:
      iex> covar([{3,8},{9,6},{5,4},{3,2}])
      1.0
  """
  @spec covar(data2D()) :: float()
  def covar(xys) when is_data2d(xys) do
    ux = xys |> Enum.map(&elem(&1, 0)) |> mean()
    uy = xys |> Enum.map(&elem(&1, 1)) |> mean()
    do_covar(xys, ux, uy)
  end

  # -----------------
  # private functions
  # -----------------

  # sum of square of differences to mean
  @spec sumsqd(data1D(), float(), float()) :: float()
  defp sumsqd(xs, u, sq \\ 0.0)
  defp sumsqd([x | xs], u, sq), do: sumsqd(xs, u, sq + sq(x - u))
  defp sumsqd([], _u, sq), do: sq

  # variance - average sum of square of differences to mean
  @spec do_var(data1D(), float(), {non_neg_integer(), float()}) :: float()
  defp do_var(xs, u, n_sq \\ {0, 0.0})
  defp do_var([x | xs], u, {n, sq}), do: do_var(xs, u, {n + 1, sq + sq(x - u)})
  defp do_var([], _u, {n, sq}), do: sq / n

  # covariance - average product of differences to means
  @spec do_covar(data2D(), float(), float(), {non_neg_integer(), float()}) ::
          float()
  defp do_covar(xys, ux, uy, n_pr \\ {0, 0.0})

  defp do_covar([{x, y} | xys], ux, uy, {n, pr}) do
    do_covar(xys, ux, uy, {n + 1, pr + (x - ux) * (y - uy)})
  end

  defp do_covar([], _ux, _uy, {n, pr}), do: pr / n

  # root mean square in a single pass
  @spec do_rms(data1D(), non_neg_integer(), float()) :: float()
  defp do_rms(xs, n \\ 0, sq \\ 0.0)
  defp do_rms([x | xs], n, sq), do: do_rms(xs, n + 1, sq + sq(x))
  defp do_rms([], n, sq), do: Exa.Math.sqrt(sq / n)

  # count and mean in a single pass
  @spec n_mean(data1D(), non_neg_integer(), float()) :: {E.count(), float()}
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

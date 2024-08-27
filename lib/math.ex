defmodule Exa.Math do
  @moduledoc """
  Math functions, trig functions, 
  and approximate floating-point arithmetic.
  """

  use Exa.Constants

  import Exa.Types
  alias Exa.Types, as: E

  # -----------------------
  # floating point / number
  # -----------------------

  @doc "Minimum augmented with +- infinities."
  @spec infmin(E.inf_number(), E.inf_number()) :: E.inf_number()
  def infmin(:neg_inf, _), do: :neg_inf
  def infmin(:pos_inf, x), do: x
  def infmin(_, :neg_inf), do: :neg_inf
  def infmin(x, :pos_inf), do: x
  def infmin(x, y), do: min(x, y)

  @doc "Maximum augmented with +- infinities."
  @spec infmax(E.inf_number(), E.inf_number()) :: E.inf_number()
  def infmax(:neg_inf, x), do: x
  def infmax(:pos_inf, _), do: :pos_inf
  def infmax(x, :neg_inf), do: x
  def infmax(_, :pos_inf), do: :pos_inf
  def infmax(x, y), do: max(x, y)

  @doc "Sign polarity of a number (float or int)."
  @spec sgn(number()) :: -1 | 0 | 1
  def sgn(i) when is_integer(i), do: isgn(i)
  def sgn(x) when is_float(x), do: fsgn(x)

  defp isgn(0), do: 0
  defp isgn(i) when i > 0, do: 1
  defp isgn(_), do: -1

  defp fsgn(+0.0), do: 0
  defp fsgn(-0.0), do: 0
  defp fsgn(x) when x > 0.0, do: 1
  defp fsgn(_), do: -1

  @doc "Clamp a number to a range."
  @spec clamp(number(), number(), number()) :: number()
  def clamp(p, x, q) when is_number(x) and is_number(p) and is_number(q) and p < q do
    clamp_(p, x, q)
  end

  @doc "Raw clamp without type and range guards."
  @spec clamp_(number(), number(), number()) :: number()
  def clamp_(p, x, _) when x < p, do: p
  def clamp_(_, x, q) when x > q, do: q
  def clamp_(_, x, _), do: x

  @doc "Integer to byte by clamping."
  @spec byte(integer()) :: byte()
  def byte(i) when is_integer(i), do: clamp_(0, i, 255)

  @doc "Float to unit range by clamping."
  @spec unit(float()) :: E.unit()
  def unit(x) when is_float(x), do: clamp_(0.0, x, 1.0)

  # -------------------------
  # approximate fp arithmetic
  # -------------------------

  @doc """
  Compare two floating point numbers.

  The result is the first argument in comparison to the second.

  Ref: https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
  """
  @spec compare(float(), float(), E.epsilon()) :: E.compare()
  def compare(x, y, eps \\ @epsilon) when is_float(x) and is_float(y), do: cmp(x, y, eps)

  defp cmp(x, x, _), do: :equal

  defp cmp(x, y, eps) do
    diff = x - y
    delta = Enum.max([abs(x), abs(y), 1.0]) * eps

    cond do
      diff > delta -> :above
      diff < -delta -> :below
      true -> :equal
    end
  end

  @doc "Compare a floating point number to 0.0"
  @spec compare0(float(), E.epsilon()) :: E.compare()
  def compare0(x, eps \\ @epsilon), do: compare(x, 0.0, eps)

  @doc "Compare a floating point number to +1.0"
  @spec compare1(float(), E.epsilon()) :: E.compare()
  def compare1(x, eps \\ @epsilon), do: compare(x, 1.0, eps)

  @doc "Test floats for equality, subject to a tolerance."
  @spec equals?(float(), float(), E.epsilon()) :: bool()
  def equals?(p, q, eps \\ @epsilon) when is_float(p) and is_float(q) and is_eps(eps) do
    compare(p, q, eps) == :equal
  end

  @doc "Test if float equals zero, subject to a tolerance."
  @spec zero?(float(), E.epsilon()) :: bool()
  def zero?(p, eps \\ @epsilon) when is_float(p) and is_eps(eps), do: equals?(p, 0.0, eps)

  @doc "Test if float equals one, subject to a tolerance."
  @spec one?(float(), E.epsilon()) :: bool()
  def one?(p, eps \\ @epsilon) when is_float(p) and is_eps(eps), do: equals?(p, 1.0, eps)

  @doc "Test if float is strictly positive, subject to a tolerance."
  @spec pos?(float(), E.epsilon()) :: bool()
  def pos?(p, eps \\ @epsilon) when is_float(p) and is_eps(eps), do: p > eps

  @doc "Test if float is non-negative, subject to a tolerance."
  @spec nonneg?(float(), E.epsilon()) :: bool()
  def nonneg?(p, eps \\ @epsilon) when is_float(p) and is_eps(eps), do: p > -eps

  @doc "Test if a float is an integer, within tolerance."
  @spec int?(float(), E.epsilon()) :: bool()
  def int?(x, eps \\ @epsilon) when is_float(x) and is_eps(eps) do
    equals?(x, Float.round(x), eps)
  end

  @doc "Test if a float value is in the unit interval, subject to a tolerancee."
  @spec unit?(float(), E.epsilon()) :: bool()
  def unit?(x, eps \\ @epsilon) do
    case between(0.0, x, 1.0, eps) do
      :below_min -> false
      :above_max -> false
      _ -> true
    end
  end

  @doc """
  Get the percentage change between two values,
  relative to the first value.

  The percent will be negative if the direction of change 
  is different from the sign of the first value.

  ## Examples:
     iex> percent(100,105)
     5.0
     iex> percent(100,95)
     -5.0
     iex> percent(-100,-105)
     5.0
     iex> percent(-100,-95)
     -5.0
  """
  @spec percent(number(), number()) :: float()
  def percent(x, y) when is_number(x) and is_number(y), do: 100.0 * (y - x) / x

  @doc """
  Snap float to integer, if it is close.

  Pass through if it is already an integer. 

  Otherwise return the original float.
  """
  @spec snapi(number(), E.epsilon()) :: number()
  def snapi(x, eps \\ @epsilon)

  def snapi(i, _) when is_integer(i), do: i

  def snapi(x, eps) when is_float(x) and is_eps(eps) do
    if int?(x, eps), do: trunc(round(x)), else: x
  end

  @doc """
  Snap a float to another float, if it is close.

  If the first argument is equal to the second, 
  with tolerance, then return the second float.

  Otherwise just return the first float.
  """
  @spec snapf(float(), float(), E.epsilon()) :: float()
  def snapf(x, y, eps \\ @epsilon) when is_float(x) and is_float(y) and is_eps(eps) do
    if equals?(x, y, eps), do: y, else: x
  end

  @doc """
  Round a float to significant decimal places relative to a tolerance.
  """
  @spec fp_round(float(), E.epsilon()) :: float()
  def fp_round(x, eps \\ @epsilon) when is_float(x) and is_eps(eps) do
    dp = 1 - (eps |> :math.log10() |> trunc())
    Float.round(x, max(0, dp))
  end

  @doc """
  Test if one value is within a range, 
  subject to a tolerance.

  Tests integers exactly against an integer range.
  Test numbers against a float range, within a tolerance.
  """
  @spec between(number(), number(), number(), E.epsilon()) :: E.between()
  def between(p, x, q, eps \\ @epsilon)

  def between(imin, i, imax, _eps) when is_range(imin, imax) and is_integer(i) do
    cond do
      i < imin -> :below_min
      i == imin -> :equal_min
      i < imax -> :between
      i == imax -> :equal_max
      i > imax -> :above_max
    end
  end

  def between(xmin, x, xmax, eps) when is_rangef(xmin, xmax) and is_number(x) and is_eps(eps) do
    case compare(x, xmin, eps) do
      :below ->
        :below_min

      :equal ->
        :equal_min

      :above ->
        case compare(x, xmax, eps) do
          :below -> :between
          :equal -> :equal_max
          :above -> :above_max
        end
    end
  end

  @doc """
  Get the fractional part of a float.

  The result is zero or positive `0.0 <= x < 1.0`.

  Negative numbers return the positive fractional part 
  above the next lowest negative integer.

  All positive or negative integers return 0.0.
  The value is never exactly 1.0.
  ## Examples
      iex> frac(0.0)
      0.0
      iex> frac(0.9)
      0.9
      iex> frac(1.0)
      0.0
      iex> frac(1.1)
      0.10000000000000009
      iex> frac(-0.9)
      0.09999999999999998
      iex> frac(-1.0)
      0.0
      iex> frac(-1.1)
      0.8999999999999999
  """
  @spec frac(float()) :: float()
  def frac(x), do: x - floor(x)

  @doc """
  Get the fractional part of a float,
  but mirror at odd integer boundaries,
  so the output is a continuous sawtooth pattern.

  The result is zero or positive `0.0 <= x <= 1.0`.

  Negative numbers return the positive fractional part 
  to the nearest even integer.

  All even integers return 0.0.
  All odd integers return 1.0.
  ## Examples
      iex> frac_mirror(0.0)
      0.0
      iex> frac_mirror(0.1)
      0.1
      iex> frac_mirror(1.0)
      1.0
      iex> frac_mirror(1.1)
      0.8999999999999999
      iex> frac_mirror(-0.1)
      0.1
      iex> frac_mirror(-1.0)
      1.0
      iex> frac_mirror(-1.1)
      0.8999999999999999
  """
  @spec frac_mirror(float()) :: float()
  def frac_mirror(x) do
    c = ceil(x)
    f = floor(x)
    isint = c == f
    fodd = f |> trunc() |> is_odd()

    cond do
      # odd integer
      isint and fodd -> 1.0
      fodd -> c - x
      true -> x - f
    end
  end

  @doc """
  Get the signed fractional part of a float.
  The result is in the range `-1.0 < x <= 1.0`.

  The output is a sawtooth
  with sharp discontinuities 
  at odd intgeger boundaries.
  The value at the discontinuity 
  is always +1.0, never -1.0
  (single-valued property).

  All even integers return 0.0.
  All odd integers return 1.0.

  The canonical example is longitude modulo 180,
  cycling from (-1) -180 through 0 to (+1) +180, 
  with a sharp discontinuity at the date-line meridian,
  where it changes from +180 to -180.
  Note that the value at the discontinuity is always +180.0.
  ## Examples
      iex> frac_sign(0.0)
      0.0
      iex> frac_sign(0.9)
      0.9
      iex> frac_sign(1.0)
      1.0
      iex> frac_sign(1.1)
      -0.8999999999999999
      iex> frac_sign(-0.9)
      -0.9
      iex> frac_sign(-1.0)
      1.0
      iex> frac_sign(-1.1)
      0.8999999999999999
  """
  @spec frac_sign(float()) :: float()
  def frac_sign(x) do
    c = ceil(x)
    f = floor(x)
    isint = c == f
    fodd = f |> trunc() |> is_odd()

    cond do
      # odd integer
      isint and fodd -> 1.0
      fodd -> x - c
      true -> x - f
    end
  end

  @doc """
  Get the signed fractional part of a float,
  but mirror at integer boundaries,
  so the output is a continuous sawtooth pattern,
  like a linear version of a sine wave.

  The result is in the range `-1.0 <= x <= 1.0`.

  All even integers have value `0.0`.
  Odd integers of the form `4n+1` have value `+1.0`.
  Odd integers of the form `4n-1` have value `-1.0`.

  The canonical example is latitude modulo 90,
  cycling from (-1) -90 through 0 to (+1) +90, 
  then declining from (+1) 90 through 0 to (-1) -90 again.
  ## Examples
      iex> frac_sign_mirror(0.0)
      0.0
      iex> frac_sign_mirror(0.9)
      0.9
      iex> frac_sign_mirror(1.0)
      1.0
      iex> frac_sign_mirror(1.1)
      0.8999999999999999
      iex> frac_sign_mirror(-0.9)
      -0.9
      iex> frac_sign_mirror(-1.0)
      -1.0
      iex> frac_sign_mirror(-1.1)
      -0.8999999999999999
  """
  @spec frac_sign_mirror(float()) :: float()
  def frac_sign_mirror(x) do
    c = ceil(x)
    f = floor(x)
    isint = c == f
    remf = f |> trunc() |> rem(4)
    remf = if remf < 0, do: remf + 4, else: remf

    case remf do
      0 -> x - f
      1 when isint -> 1.0
      1 -> c - x
      2 -> f - x
      3 when isint -> -1.0
      3 -> x - c
    end
  end

  @doc """
  Linear interpolation. 

  Does not require that the range is positive `y > x`.
  Does not clamp parameter in the range `0.0-1.0`.

  ## Examples
      iex> lerp(1.0,0.0,2.0)
      1.0
      iex> lerp(1.0,1.0,2.0)
      2.0
      iex> lerp(1.0,0.5,2.0)
      1.5
      iex> lerp(1.0,-1.0,2.0)
      0.0
  """
  @spec lerp(float(), E.param(), float()) :: float()
  def lerp(x, t, y) when is_float(x) and is_param(t) and is_float(y), do: x + t * (y - x)

  @doc """
  Return a linear interpolation function with arity 1.
   
  An optimization that precalculates the difference of the endpoints.
  """
  @spec lerp_fun(float(), float()) :: (float() -> float())
  def lerp_fun(x, y) when is_float(x) and is_float(y), do: fn t -> x + t * (y - x) end

  # ------------
  # trigonometry
  # ------------

  @doc "Convert E.degrees to radians."
  @spec deg2rad(E.degrees()) :: E.radians()
  def deg2rad(deg) when is_float(deg), do: deg * @pi_180

  @doc "Convert radians to degrees."
  @spec rad2deg(E.radians()) :: E.degrees()
  def rad2deg(rad) when is_float(rad), do: rad / @pi_180

  @doc """
  Trig function sine for decimal degrees.
  Result is in the range `[-1.0,1.0]`.
  """
  @spec sind(E.degrees()) :: E.sym_unit()
  def sind(deg), do: deg |> deg2rad() |> :math.sin()

  @doc """
  Trig function cosine for decimal degrees.
  Result is in the range `[-1.0,1.0]`.
  """
  @spec cosd(E.degrees()) :: E.sym_unit()
  def cosd(deg), do: deg |> deg2rad() |> :math.cos()

  @doc "Trig function tangent for decimal degrees."
  @spec tand(E.degrees()) :: float()
  def tand(deg), do: deg |> deg2rad() |> :math.tan()

  @doc """
  Trig function inverse sine giving decimal degrees.
  Result is in the range `[-90.0, 90.0]`.
  """
  @spec asind(E.sym_unit()) :: E.degrees()
  def asind(x) when is_sym_unit(x), do: x |> :math.asin() |> rad2deg()

  @doc """
  Trig function inverse cosine giving decimal degrees.
  Result is in the range `[0.0,180.0]`.
  """
  @spec acosd(E.sym_unit()) :: E.degrees()
  def acosd(x) when is_sym_unit(x), do: x |> :math.acos() |> rad2deg()

  @doc """
  Trig function 2-quadrant inverse tangent giving decimal degrees.
  Result is in the range `[-90.0,90.0]`.
  """
  @spec atand(float()) :: E.degrees()
  def atand(yx) when is_float(yx), do: :math.atan(yx) |> rad2deg()

  @doc """
  Trig function 4-quadrant inverse tangent giving decimal degrees.

  Note the order of arguments is y then x.

  Result is in the range `[-180.0,180.0]`.
  """
  @spec atand(float(), float()) :: E.degrees()
  def atand(y, x) when is_float(y) and is_float(x), do: :math.atan2(y, x) |> rad2deg()
end

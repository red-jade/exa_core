defmodule Exa.Convert do
  @moduledoc "Conversions for basic types."

  alias Exa.Math

  import Exa.Types
  alias Exa.Types, as: E

  @doc "Unit float to byte."
  @spec f2b(E.unit()) :: byte()
  def f2b(x) when is_float(x), do: Math.clamp_(0, trunc(256.0 * x), 255)

  @doc "Byte to unit float."
  @spec b2f(byte()) :: E.unit()
  def b2f(b) when is_integer(b), do: Math.clamp_(0.0, b / 255.0, 1.0)

  @doc "Byte to zero-padded 2-digit hex string."
  @spec b2h(byte()) :: String.t()
  def b2h(b) when is_integer(b) do
    Math.clamp_(0, b, 255)
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  @doc "2-digit hex string to byte."
  @spec h2b(String.t()) :: byte()
  def h2b(s) when is_string_fix(s, 2), do: s |> Integer.parse(16) |> elem(0)

  @doc "Hex string to integer, e.g. Unicode codepoint."
  @spec h2i(String.t()) :: pos_integer()
  def h2i(s), do: s |> Integer.parse(16) |> elem(0)

  @doc "Decimal string to integer."
  @spec d2i(String.t()) :: pos_integer()
  def d2i(s), do: s |> Integer.parse() |> elem(0)

  @doc "Unit float to 2-digit zero-padded hex string."
  @spec f2h(E.unit()) :: String.t()
  def f2h(x) when is_float(x) do
    x
    |> f2b()
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  @doc "2-digit hex string to unit float."
  @spec h2f(String.t()) :: E.unit()
  def h2f(s) when is_string_fix(s, 2), do: h2b(s) / 255.0
end

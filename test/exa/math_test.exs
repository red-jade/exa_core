defmodule Exa.MathTest do
  use ExUnit.Case

  import Exa.Math

  doctest Exa.Math

  test "frac" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 0.0, 0.1, 0.6, 0.0, 0.1, 0.7, 0.0, 0.2] =
             vals |> Enum.map(&frac(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac mirror" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 1.0, 0.9, 0.4, 0.0, 0.1, 0.7, 1.0, 0.8] =
             vals |> Enum.map(&frac_mirror(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac sign" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, -0.8] =
             vals |> Enum.map(&frac_sign(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac sign mirror" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [-0.9, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 0.8] =
             vals |> Enum.map(&frac_sign_mirror(&1)) |> Enum.map(&fp_round(&1))
  end
end

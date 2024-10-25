defmodule Exa.MathTest do
  use ExUnit.Case

  import Exa.Types
  import Exa.Math
  import Exa.Combine
  import Exa.Stats
  import Exa.Random

  doctest Exa.Math
  doctest Exa.Combine
  doctest Exa.Stats

  test "frac" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 0.0, 0.1, 0.6, 0.0, 0.1, 0.7, 0.0, 0.2] ==
             vals |> Enum.map(&frac(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac mirror" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 1.0, 0.9, 0.4, 0.0, 0.1, 0.7, 1.0, 0.8] ==
             vals |> Enum.map(&frac_mirror(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac sign" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [0.9, 1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, -0.8] ==
             vals |> Enum.map(&frac_sign(&1)) |> Enum.map(&fp_round(&1))
  end

  test "frac sign mirror" do
    vals = [-1.1, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 1.2]

    assert [-0.9, -1.0, -0.9, -0.4, 0.0, 0.1, 0.7, 1.0, 0.8] ==
             vals |> Enum.map(&frac_sign_mirror(&1)) |> Enum.map(&fp_round(&1))
  end

  test "flaky random test" do
    ntest = 1..10

    Enum.each(ntest, fn _ ->
      b = uniform_bit()
      assert is_bit(b)
    end)

    Enum.each(ntest, fn _ ->
      i = uniform_int(100)
      assert is_in_range(1, i, 100)
    end)

    Enum.each(ntest, fn _ ->
      i = uniform_int(12, 27)
      assert is_in_range(12, i, 27)
    end)

    Enum.each(ntest, fn _ ->
      i = uniform_int(-20, 20)
      assert is_in_range(-20, i, 20)
    end)

    Enum.each(ntest, fn _ ->
      x = uniform_float0()
      assert is_unit(x) and x != 1.0
    end)

    Enum.each(ntest, fn _ ->
      x = uniform_float()
      assert is_unit(x) and not is_zero(x)
    end)
  end
end

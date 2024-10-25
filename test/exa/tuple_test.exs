defmodule Exa.TupleTest do
  use ExUnit.Case
  import Exa.Types

  import Exa.Tuple

  doctest Exa.Tuple

  test "to string" do
    assert to_string({}) == "{}"
    assert to_string({:foo}) == "{foo}"
    assert to_string({"bar"}) == "{\"bar\"}"
    assert to_string({:a, 1, :c}) == "{a,1,c}"
  end

  test "sum min max" do
    a = {1, 2, 3}
    assert min(a) == 1
    assert max(a) == 3
    assert sum(a) == 6

    b = {99.0, 3.14, -42}
    assert min(b) == -42
    assert max(b) == 99
    assert sum(b) == 60.14
  end

  test "all? any?" do
    a = {6, 10, 99}

    assert all?(a, &(&1 < 100))
    assert any?(a, &(&1 < 10))

    assert not all?(a, &(&1 != 6))
    assert not all?(a, &(&1 != 10))
    assert not all?(a, &(&1 != 99))

    assert not any?(a, &(&1 < 0))
  end

  test "zip dot" do
    assert {1} = zip_with({2}, {1}, &(&1 - &2))

    a = {1, 2, 3}
    b = {4, 5, 6}
    assert {4, 10, 18} == zip_with(a, b, &(&1 * &2))

    assert {{1, 3}, {2, 4}} = zip_with({1, 2}, {3, 4}, &{&1, &2})

    assert {3, 8} == dot({1, 2}, {3, 4})
    assert {3, 8, 15, 24} == dot({1, 2, 3, 4}, {3, 4, 5, 6})
  end

  test "map filter reduce bireduce" do
    assert [{1,2},{5,5}] == filter([{1,2},{4,3},{5,5}], 0, &is_int_odd(&1))

    assert {1,4,9} == map({1,2,3}, fn i -> i * i end)

    assert 26 == bireduce({1, 2, 3}, {3, 4, 5}, 0, fn x, y, acc -> acc + (x*y) end)
  end
end

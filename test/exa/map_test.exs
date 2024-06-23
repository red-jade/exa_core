defmodule Exa.MapTest do
  use ExUnit.Case

  doctest Exa.Map

  import Exa.Map

  test "map" do
    abc = %{"a" => -1, "b" => 2, "c" => 3}
    assert %{"a" => 1, "b" => 4, "c" => 9} == map(abc, fn x -> x * x end)
  end

  test "invert!" do
    bij = %{"a" => 1, "b" => 2, "c" => 3}
    assert %{1 => "a", 2 => "b", 3 => "c"} == invert!(bij)

    bad = %{:a => 1, :b => 1, :c => 3}
    assert_raise RuntimeError, fn -> invert!(bad) end
  end

  test "invert" do
    bij = %{"a" => 1, "b" => 2, "c" => 3}
    assert %{1 => ["a"], 2 => ["b"], 3 => ["c"]} == invert(bij)

    multi = %{:a => 1, :b => 1, :c => 3}
    assert %{1 => [:a, :b], 3 => [:c]} == invert(multi)
  end

  test "key" do
    bij = %{"a" => 1, "b" => 2, "c" => 3}
    assert "c" == key(bij, 3)
    assert "a" == key(bij, 1)
    assert is_nil(key(bij, 99))

    multi = %{:a => 1, :b => 1, :c => 3}
    assert key(multi, 3) == :c
    assert key(multi, 1) in [:a, :b]
    assert is_nil(key(multi, 99))
  end
end

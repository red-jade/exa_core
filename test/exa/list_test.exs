defmodule Exa.ListTest do
  use ExUnit.Case
  import Exa.Types
  import Exa.List

  doctest Exa.List

  test "enlist unlist wrap" do
    assert enlist(:a) == [:a]
    assert enlist([:a]) == [:a]
    assert enlist([1, 2, 3]) == [1, 2, 3]

    assert unlist([]) == nil
    assert unlist([:a]) == :a
    assert unlist([1, 2, 3]) == [1, 2, 3]

    assert wrap([], 1, 2) == [1, 2]
    assert wrap([2, 3, 4], 1, 5) == [1, 2, 3, 4, 5]
    assert wrap(~c"abc", ?{, ?}) == ~c"{abc}"
  end

  test "unique" do
    assert unique?([]) == true
    assert unique?([1, 2, 3]) == true
    assert unique?([1, 2, 3, 2, 1]) == false
    assert unique?([:a, 2, false]) == true
    assert unique?([2, 2.0]) == true
    assert unique?([2.000000000, 2.0]) == false
  end

  test "duplicates" do
    assert duplicates([]) == []
    assert duplicates([1, 2, 3]) == []
    assert duplicates([1, 2, 3, 2, 1]) |> Enum.sort() == [1, 2]
    assert duplicates([1, 1, 1, 1, 1]) == [1]
    assert duplicates([:a, :b, :c]) == []
    assert duplicates([:a, :b, :c, :b, :b]) == [:b]
    assert duplicates([:a, :b, :c, :b, :a]) |> Enum.sort() == [:a, :b]
  end

  test "take all while" do
    assert_raise ArgumentError, fn ->
      take_all_while([1, 2, 3, 4], 0, fn x, sum -> {sum + x < 4, sum + x} end)
    end
  end
end

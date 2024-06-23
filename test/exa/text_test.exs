defmodule Exa.TextTest do
  use ExUnit.Case
  import Exa.Text

  doctest Exa.Text

  test "term to string" do
    assert term_to_string("") == ~s'""'
    assert term_to_string("foo") == ~s'"foo"'
    assert term_to_string([:a, 1, "b", false, 3.14]) == ~s'[a,1,"b",false,3.14]'
    assert term_to_string([1, 2, 3]) == "[1,2,3]"
    assert term_to_string({1, 2, 3}) == "{1,2,3}"
    assert term_to_string([:a, 1, {:b, 2}]) == "[a,1,{b,2}]"
    assert term_to_string({:b, 2, [:a, 1]}) == "{b,2,[a,1]}"
  end

  test "text length" do
    # TODO: add unicode tests
    assert text_length([]) == 0
    assert text_length("") == 0
    assert text_length([""]) == 0
    assert text_length(["foo"]) == 3
    assert text_length([?>]) == 1
    assert text_length([?<, "foo", ?>, [?<, ?/, "foo", ?>]]) == 11
  end

  test "text count" do
    assert text_count("", ?a) == 0
    assert text_count("foo", ?o) == 2
    assert text_count([?a, ?b, "cd", [?x, "yz"], ?e, "cfg"], ?a) == 1
    assert text_count([?a, ?b, "cd", [?x, "yz"], ?e, "cfg"], ?c) == 2
    assert text_count([?a, ?b, "cd", [?x, "yz"], ?e, "cfg"], ?z) == 1
    assert text_count([?<, "foo", ?>, [?<, ?/, "foo", ?>]], ?f) == 2
    assert text_count([?<, "foo", ?>, [?<, ?/, "foo", ?>]], ?<) == 2
  end

  test "pivot" do
    assert [] = text_pivot([])
    assert [1] = text_pivot([1])
    assert [3, 2, 1] = text_pivot([1, 2, 3])
    assert [[3, 2, 1]] = text_pivot([[1, 2, "", 3]])
    assert [5, [4, 3], 2, 1] = text_pivot([1, 2, [3, 4], 5])
    assert [5, [4, 3], 2, 1] = text_pivot([1, "", 2, ["", 3, 4, []], [], 5])
  end

  test "text reverse" do
    assert text_reverse("") == ""
    assert text_reverse("foo") == "oof"

    txt1 = [?a, ?b, "cd", [?x, "yz"], ?e, "cfg"]
    txt2 = ["gfc", ?e, ["zy", ?x], "dc", ?b, ?a]
    testrev(txt1)
    testrev(txt2)
    assert text_reverse(txt1) == txt2

    txt3 = [?<, "foo", ?>, [?<, ?/, "foo", ?>]]
    testrev(txt3)
  end

  test "text take" do
    assert text_take("", ?f) == ""
    assert text_take("foo", ?f) == ""
    assert text_take("foo", ?o) == "f"
    assert text_take("foo", ?z) == "foo"

    txt1 = [?a, ?b, "cd", [?x, "yz"], ?e, "cfg"]
    txt2 = ["gfc", ?e, ["zy", ?x], "dc", ?b, ?a]
    assert text_take(txt1, ?y) == "abcdx"
    assert text_take(txt2, ?b) == "gfcezyxdc"
  end

  test "text line col" do
    assert text_line_col("") == {1, 0}
    assert text_line_col("abc") == {1, 3}
    assert text_line_col("abc\n") == {2, 0}
    assert text_line_col(["abc\n", [?1, "23", ?\n], "xy", ?z]) == {3, 3}
  end

  defp testrev(txt) do
    # rev is self-inverse
    assert txt |> text_reverse |> text_reverse == txt
    # rev and str commute
    assert txt |> text_reverse |> text_to_string == txt |> text_to_string |> String.reverse()
  end
end

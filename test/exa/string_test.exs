defmodule Exa.StringTest do
  use ExUnit.Case
  import Exa.String

  doctest Exa.String

  test "normalize" do
    assert " f o o " == normalize("      f\t\t\n\r  o \s\s o  ")
  end

  test "wrap string" do
    assert "" |> wraps("{", "}") == "{}"
    assert "foo" |> wraps == ~s'"foo"'
    assert "foo" |> wraps(">", "<") == ">foo<"
    assert 1..3 |> Enum.join(",") |> wraps("[", "]") == "[1,2,3]"
  end

  test "unwrap string" do
    assert "" |> unwraps == ""
    assert ~s'"foo"' |> unwraps == "foo"
    assert ">foo<" |> unwraps(">", "<") == "foo"
    assert "[1,2,3]" |> unwraps("[", "]") == "1,2,3"
    assert ~s'"abc' |> unwraps == "abc"
    assert ~s'abc"' |> unwraps == "abc"
  end

  test "count and contains" do
    assert contains?("foo", ?f) == true
    assert contains?("foo", ?z) == false
    assert count("+", ?z) == 0
    assert count("+", ?+) == 1
    assert count("1+2+3+4", ?+) == 3
    assert count("1+2-3*4", ~c"+-*") == 3
    assert count("1.2E10", ~c".Ee") == 2
  end

  test "summary" do
    assert summary("foo") == "foo"
    assert summary("trunc", 5) == "trunc"
    assert summary("trunca", 5) == "tr..."
    assert summary("truncation", 5) == "tr..."
  end

  test "escape" do
    assert escape("foo", ~c"{}[]()") == "foo"
    assert escape("+", ~c"+") == ~S"\+"
    assert escape("'", ~c(')) == ~S"\'"
    assert escape("\\", ~c"\\") == ~S"\\"
  end

  test "regex escape" do
    assert escape_regex("foo") == "foo"
    assert escape_regex("+{}") == ~S"\+\{}"
    assert escape_regex(~S"a\b") == ~S"a\b"
  end

  test "utf8" do
    assert "41" = utf8_hex(?A)
    assert "E29480" = utf8_hex(0x2500)
  end

  test "ordinal" do
    one = Enum.reduce(1..10, "", fn i, s -> s <> ordinal(i, ?1) end)
    assert one == "12345678910"

    az = Enum.reduce(1..26, "", fn i, s -> s <> ordinal(i, ?a) end)
    assert az == "abcdefghijklmnopqrstuvwxyz"

    az = Enum.reduce(1..26, "", fn i, s -> s <> ordinal(i, ?A) end)
    assert az == "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    r01_10 = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    r11_20 = ["XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

    assert r01_10 == Enum.map(1..10, &ordinal(&1, ?I))
    assert r11_20 == Enum.map(11..20, &ordinal(&1, ?I))
  end
end

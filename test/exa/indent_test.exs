defmodule Exa.IndentTest do
  use ExUnit.Case
  import Exa.Indent

  doctest Exa.Indent

  test "construction and endl" do
    out = indent()
    assert out.ws == [""]
    assert out.tab == "  "
    assert out |> to_string == ""
    assert line_col(out) == {1, 0}

    assert indent(0, 0, ascii_delims(), "def") |> push |> pop |> to_string == "def"

    assert indent() |> push |> pop |> to_string == ""
    assert indent() |> endl |> to_string == "\n"
    assert indent() |> newl |> to_string == ""
    assert indent() |> line |> to_string == "\n"
    assert indent() |> newl |> endl |> to_string == "\n"
    assert indent() |> line |> line |> to_string == "\n\n"
  end

  test "fixed width str" do
    assert indent() |> str("foo", 3, :left) |> to_string == "foo"
    assert indent() |> str("foo", 3, :right) |> to_string == "foo"
    assert indent() |> str("foo", 5, :left) |> to_string == "foo  "
    assert indent() |> str("foo", 5, :right) |> to_string == "  foo"
    assert indent() |> str("foobar", 4, :left) |> to_string == "foob"
    assert indent() |> str("foobar", 4, :right) |> to_string == "obar"
  end

  test "fixed width txt" do
    assert indent() |> txt([?f, "o", ?o], 3, :left) |> to_string == "foo"
    assert indent() |> txt([?f, "o", ?o], 3, :right) |> to_string == "foo"
    assert indent() |> txt([?f, "o", ?o], 5, :left) |> to_string == "foo  "
    assert indent() |> txt([?f, "o", ?o], 5, :right) |> to_string == "  foo"
    assert indent() |> txt([?f, "ooba", ?r], 4, :left) |> to_string == "foob"
    assert indent() |> txt([?f, "ooba", ?r], 4, :right) |> to_string == "obar"
  end

  test "simple text" do
    assert indent() |> txt("foo") |> to_string == "foo"
    assert indent() |> str("foo") |> to_string == "\"foo\""
    assert indent() |> str(:bar) |> to_string == "bar"
    assert indent() |> str(1) |> to_string == "1"
    assert indent() |> str(3.14) |> to_string == "3.14"
    assert indent() |> chr(?A) |> to_string == "A"
    assert indent() |> txt("a") |> chr(?,) |> str(:b) |> chr(?;) |> to_string == "a,b;"
  end

  test "margins and tabs" do
    # margin
    assert indent(2, 1) |> newl |> str("foo") |> to_string == " \"foo\""
    assert indent(2, 1) |> newl |> txt("foo") |> to_string == " foo"
    assert indent(2, 3) |> newl |> str(:bar) |> to_string == "   bar"
    # tabs
    assert indent() |> push |> newl |> str(1) |> to_string == "  1"
    assert indent() |> push |> push |> newl |> str(1) |> to_string == "    1"
    assert indent() |> push |> pop |> newl |> str(1) |> to_string == "1"
    assert indent() |> pop |> newl |> str(1) |> to_string == "1"
    assert indent() |> push |> pop |> pop |> newl |> str(1) |> to_string == "1"
    # margin and tabs
    assert indent(2, 1) |> newl |> str(:z) |> to_string == " z"
    assert indent(2, 1) |> push |> newl |> str(:z) |> to_string == "   z"
    assert indent(2, 1) |> push |> push |> newl |> str(:z) |> to_string == "     z"
    assert indent(2, 1) |> push |> pop |> newl |> str(:z) |> to_string == " z"
    assert indent(2, 1) |> pop |> newl |> str(:z) |> to_string == " z"
    assert indent(2, 1) |> push |> pop |> pop |> newl |> str(:z) |> to_string == " z"
  end

  test "string margins and tabs" do
    # margin
    assert indent(2, "|") |> newl |> str("foo") |> to_string == "|\"foo\""
    assert indent(2, "|") |> newl |> txt("foo") |> to_string == "|foo"
    assert indent(2, "| ") |> newl |> str(:bar) |> to_string == "| bar"
    # tabs
    assert indent(2, "| ") |> push |> newl |> str(1) |> to_string == "|   1"
    assert indent(2, "| ") |> push |> push |> newl |> str(1) |> to_string == "|     1"
    assert indent(2, "| ") |> push |> pop |> newl |> str(1) |> to_string == "| 1"
    assert indent(2, "| ") |> pop |> newl |> str(1) |> to_string == "| 1"
    assert indent(2, "| ") |> push |> pop |> pop |> newl |> str(1) |> to_string == "| 1"
    # # margin and tabs
    assert indent("- ", 1) |> newl |> str(:z) |> to_string == " z"
    assert indent("- ", 1) |> push |> newl |> str(:z) |> to_string == " - z"
    assert indent("- ", 1) |> push |> push |> newl |> str(:z) |> to_string == " - - z"
    assert indent("- ", 1) |> push |> pop |> newl |> str(:z) |> to_string == " z"
    assert indent("- ", 1) |> pop |> newl |> str(:z) |> to_string == " z"
    assert indent("- ", 1) |> push |> pop |> pop |> newl |> str(:z) |> to_string == " z"
  end

  test "lines" do
    assert indent() |> lines(3) |> to_string == "\n\n\n"
    assert indent() |> strl("foo") |> to_string == "\"foo\"\n"
    assert indent() |> txtl("foo") |> to_string == "foo\n"
    assert indent() |> push |> txtl("foo") |> to_string == "  foo\n"
    assert indent() |> txtl("foo") |> txtl("bar") |> to_string == "foo\nbar\n"
    assert indent() |> newl |> txt("foo") |> endl |> to_string == "foo\n"
    assert indent() |> push |> newl |> txt("foo") |> endl |> to_string == "  foo\n"
    assert indent() |> txtl("foo") |> push |> txtl("bar") |> to_string == "foo\n  bar\n"

    txt = indent() |> txtl("foo") |> push |> txtl("bar") |> pop |> txtl("baz") |> to_string

    assert txt == "foo\n  bar\nbaz\n"
  end

  test "ascii rows" do
    dels = ascii_delims()
    {_hchar, vchar, _tmbdels} = dels
    assert indent(2, 0, dels) |> row([1, 2, 3], 3, vchar) |> to_string == "|1  |2  |3  |\n"

    assert indent(2, 0, dels) |> sep(:top, {3, 3}) |> to_string == "+---+---+---+\n"
    assert indent(2, 0, dels) |> sep(:middle, [1, 2, 3]) |> to_string == "+-+--+---+\n"
    assert indent(2, 0, dels) |> sep(:bottom, [1, 3, 2]) |> to_string == "+-+---+--+\n"

    indent(2, 2, dels) |> line |> table(["A", "B", "C"], [[1, 2, 3]], 3) |> IO.puts()
  end

  test "light unicode rows" do
    dels = light_delims()
    {_hchar, vchar, _tmbdels} = dels

    assert indent(2, 0, dels)
           |> row([1, 2, 3], 3, vchar)
           |> to_string == "\u25021  \u25022  \u25023  \u2502\n"

    assert indent(2, 0, dels)
           |> sep(:top, {3, 3})
           |> to_string ==
             "\u250C\u2500\u2500\u2500\u252C\u2500\u2500\u2500\u252C\u2500\u2500\u2500\u2510\n"

    assert indent(2, 0, dels)
           |> sep(:middle, [1, 2, 3])
           |> to_string == "\u251C\u2500\u253C\u2500\u2500\u253C\u2500\u2500\u2500\u2524\n"

    assert indent(2, 0, dels)
           |> sep(:bottom, [1, 3, 2])
           |> to_string == "\u2514\u2500\u2534\u2500\u2500\u2500\u2534\u2500\u2500\u2518\n"

    indent(2, 2, dels) |> line |> table(["A", "B", "C"], [[1, 2, 3]], 3) |> IO.puts()
  end

  test "light horizontal unicode rows" do
    dels = light_horiz_delims()
    indent(2, 2, dels) |> line |> table(["A", "B", "C"], [[1, 2, 3]], 3) |> IO.puts()
  end

  test "heavy unicode rows" do
    dels = heavy_delims()
    {_hchar, vchar, _tmbdels} = dels

    assert indent(2, 0, dels)
           |> row([1, 2, 3], 3, vchar)
           |> to_string == "\u25031  \u25032  \u25033  \u2503\n"

    assert indent(2, 0, dels)
           |> sep(:top, {3, 3})
           |> to_string ==
             "\u250F\u2501\u2501\u2501\u2533\u2501\u2501\u2501\u2533\u2501\u2501\u2501\u2513\n"

    assert indent(2, 0, dels)
           |> sep(:middle, [1, 2, 3])
           |> to_string == "\u2523\u2501\u254B\u2501\u2501\u254B\u2501\u2501\u2501\u252B\n"

    assert indent(2, 0, dels)
           |> sep(:bottom, [1, 3, 2])
           |> to_string == "\u2517\u2501\u253B\u2501\u2501\u2501\u253B\u2501\u2501\u251B\n"

    indent(2, 2, dels) |> line |> table(["A", "B", "C"], [[1, 2, 3]], 3) |> IO.puts()
  end

  test "heavy horizontal unicode rows" do
    dels = heavy_horiz_delims()
    indent(2, 2, dels) |> line |> table(["A", "B", "C"], [[1, 2, 3]], 3) |> IO.puts()
  end
end

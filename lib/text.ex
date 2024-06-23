defmodule Exa.Text do
  @moduledoc """
  Common utilities for charlists and strings.
  """

  import Exa.String, only: [count: 2]

  import Exa.Types
  alias Exa.Types, as: E

  # text handling ==========

  @typedoc "Text is a char or a String."
  @type text() :: char() | String.t()

  defguard is_text(txt) when is_string(txt) or is_char(txt)

  @typedoc """
  A deeply nested mixture of characters and strings.
  The top-level must be a list.
  This is a superset of charlist.
  A charlist only contains character codepoints.
  A charlist is a literal type using single quotes,
  and a typespec type. 
  Every charlist is also a textlist.
  """
  @type textlist() :: [text() | textlist()]

  @typedoc """
  A single string or a deep list of characters and strings
  This is the same as built-in type IO.chardata.
  Note that a raw character integer is not allowed at the top level.
  So many of the utilities defined here will fail for a single character argument.
  """
  @type textdata() :: String.t() | textlist()

  defguard is_textlist(txt)
           when is_list(txt) and (txt == [] or is_text(hd(txt)) or is_list(hd(txt)))

  defguard is_textdata(txt) when is_string(txt) or is_textlist(txt)

  @typedoc """
  The line number and column position of some text.
  Lines are numbered from 1, even for empty text.
  Columns are counted from 0 for the empty line.
  """
  @type textpos() :: {E.count1(), E.count()}

  @doc """
  Get the number of characters in textdata.

  Assumes that each integer char is a standalone character
  (could upgrade to handle codepoints or graphemes).

  Note argument type is extended to include a single character.
  """
  @spec text_length(char() | textdata()) :: E.count()
  def text_length(chr) when is_char(chr), do: 1
  def text_length(str) when is_string(str), do: String.length(str)
  def text_length(txt) when is_textlist(txt), do: len(txt, 0)

  defp len(["" | dat], n), do: len(dat, n)
  defp len([[] | dat], n), do: len(dat, n)
  defp len([c | dat], n) when is_char(c), do: len(dat, n + 1)
  defp len([s | dat], n) when is_string(s), do: len(dat, n + String.length(s))
  defp len([d | dat], n) when is_list(d), do: len(dat, n + len(d, 0))
  defp len([], n), do: n

  @doc """
  Count the number of occurrences of a character in the text.
  Assumes that each standalone character (integer codepoint)
  corresponds to a grapheme.
  The default character is newline.
  """
  @spec text_count(textdata(), char()) :: E.count()
  def text_count(txt, ch \\ ?\n)
  def text_count(str, ch) when is_string(str) and is_char(ch), do: count(str, ch)
  def text_count(txt, ch) when is_textlist(txt) and is_char(ch), do: cnt(txt, ch, 0)

  defp cnt([ch | dat], ch, n) when is_char(ch), do: cnt(dat, ch, n + 1)
  defp cnt([c | dat], ch, n) when is_char(c), do: cnt(dat, ch, n)
  defp cnt([s | dat], ch, n) when is_string(s), do: cnt(dat, ch, n + count(s, ch))
  defp cnt([d | dat], ch, n) when is_list(d), do: cnt(dat, ch, n + cnt(d, ch, 0))
  defp cnt([], _, n), do: n

  @doc """
  Pivot is a deep reversal of lists, 
  but not reversal of individual String content.
  """
  @spec text_pivot(textdata()) :: textdata()
  def text_pivot(text, out \\ [])
  def text_pivot(["" | t], out), do: text_pivot(t, out)
  def text_pivot([[] | t], out), do: text_pivot(t, out)
  def text_pivot([h | t], out) when is_list(h), do: text_pivot(t, [text_pivot(h) | out])
  def text_pivot([h | t], out), do: text_pivot(t, [h | out])
  def text_pivot([], out), do: out
  def text_pivot(str, []), do: str

  @doc """
  Deep reverse of the textdata.
  """
  @spec text_reverse(char() | textdata()) :: textdata()
  def text_reverse(chr) when is_char(chr), do: chr
  def text_reverse(str) when is_string(str), do: String.reverse(str)
  def text_reverse(txt) when is_textlist(txt), do: rev(txt, [])

  defp rev([c | dat], txt) when is_char(c), do: rev(dat, [c | txt])
  defp rev([s | dat], txt) when is_string(s), do: rev(dat, [String.reverse(s) | txt])
  defp rev([d | dat], txt) when is_list(d), do: rev(dat, [rev(d, []) | txt])
  defp rev([], txt), do: txt

  @doc """
  Take characters from the head of the textdata to build a prefix string.
  The prefix is taken until the character predicate becomes true.
  If a character is provided, the prefix will be 
  up to the first occurrence of the character.
  """
  @spec text_take(textdata(), char() | E.predicate?(char())) :: String.t()

  def text_take(txt, c) when is_char(c) do
    text_take(txt, &(&1 == c))
  end

  def text_take(str, pred) when is_string(str) and is_pred(pred) do
    text_take(String.to_charlist(str), pred)
  end

  def text_take(txt, pred) when is_textlist(txt) and is_pred(pred) do
    # don't care if it truncated or completed 
    {_, prefix} = tak(txt, pred, [])
    prefix |> Enum.reverse() |> List.to_string()
  end

  defp tak([s | dat], pred, txt) when is_string(s) and is_pred(pred) do
    tak([String.to_charlist(s) | dat], pred, txt)
  end

  defp tak([d | dat], pred, txt) when is_list(d) and is_pred(pred) do
    case tak(d, pred, txt) do
      {:end, prefix} -> {:end, prefix}
      {:cont, newtxt} -> tak(dat, pred, newtxt)
    end
  end

  defp tak([c | dat], pred, txt) when is_char(c) and is_pred(pred) do
    if pred.(c) do
      {:end, txt}
    else
      tak(dat, pred, [c | txt])
    end
  end

  defp tak([], _, txt), do: {:cont, txt}

  @doc ~S"""
  Find the line number and column position at the end of the textdata.
  The line number is 1-indexed.
  The column is 0-indexed, with 0 meaning an empty line.
  ## Examples
      iex> text_line_col( "" )
      {1,0}
      iex> text_line_col( "abc" )
      {1,3}
      iex> text_line_col( "abc\n" )
      {2,0}
      iex> text_line_col( ["abc\n",[?1,"23",?\n], "xy",?z] )
      {3,3}
  """
  @spec text_line_col(textdata()) :: textpos()
  def text_line_col(txt) when is_textdata(txt) do
    {1 + text_count(txt, ?\n), txt |> text_reverse |> text_take(?\n) |> text_length}
  end

  @doc "Convert text to a string."
  @spec text_to_string(textdata()) :: String.t()
  def text_to_string(str) when is_string(str), do: str
  def text_to_string(dat) when is_list(dat), do: List.to_string(dat)

  @doc "Convert an integer character codepoint to a binary String."
  @spec char_to_string(char) :: String.t()
  def char_to_string(c) when is_char(c), do: <<c::utf8>>

  @doc """
  Convert symbol to string, to allow override of default Kernel methods.
  An integer value will be converted as a number, not a character.
  """
  @spec term_to_string(any()) :: String.t()
  def term_to_string(s), do: s |> term_to_text() |> text_to_string

  @doc """
  Convert symbol to textdata.
  Note that integers are numbers and Strings are quoted.
  """
  @spec term_to_text(any()) :: textdata()

  def term_to_text(a) when is_atom(a), do: Kernel.to_string(a)
  def term_to_text(s) when is_string(s), do: wrap(s, ?", ?")
  def term_to_text(i) when is_integer(i), do: Kernel.to_string(i)
  def term_to_text(x) when is_float(x), do: Kernel.to_string(x)

  def term_to_text(tup) when is_tuple(tup) do
    tup |> Tuple.to_list() |> Enum.map(&term_to_text/1) |> text_join(?{, ?})
  end

  def term_to_text(list) when is_list(list) do
    list |> Enum.map(&term_to_text/1) |> text_join
  end

  def term_to_text(%MapSet{} = set) do
    set |> Enum.map(&term_to_text/1) |> text_join("<[", "]>")
  end

  def term_to_text(%{} = map) do
    map
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k != :__struct__ end)
    |> Enum.map(fn {k, v} -> [term_to_text(k), " => ", term_to_text(v)] end)
    |> text_join("%#{Map.get(map, :__struct__)}{", "}%")
  end

  def term_to_text(fun) when is_function(fun), do: "fun"

  @doc """
  Join a sequence of text elements with intermediate separators 
  and wrap with open/close delimiters.
  Suitable for textcode IOData piping.
  Default separator is comma.
  Default open/close is square brackets.
  ## Examples
      iex> [?a,"b",?c] |> text_join |> text_to_string
      "[a,b,c]"
      iex> [?x,"y",?z] |> text_join(?{,?},?:) |> text_to_string
      "{x:y:z}"
  """
  @spec text_join(textlist(), text(), text(), text()) :: textlist()
  def text_join(text, open \\ ?[, close \\ ?], sep \\ ?,)
      when is_textlist(text) and is_text(sep) and is_text(open) and is_text(close) do
    [open, Enum.intersperse(text, sep), close]
  end

  @doc """
  Wrap text in open and close delimiters.
  Text is first argument, so it is suitable for textdata fluent piping.
  Default open/close is double quote.
  ## Examples
      iex> "abc" |> wrap |> text_to_string
      "\\"abc\\""
      iex> "abc" |> wrap(?(,?)) |> text_to_string
      "(abc)"
  """
  @spec wrap(textdata(), text(), text()) :: textlist()
  def wrap(text, open \\ ?", close \\ ?")
      when is_textdata(text) and is_text(open) and is_text(close) do
    [open, text, close]
  end
end

defmodule Exa.String do
  @moduledoc """
  Utilities for Strings and text.

  Currently uses character integers 
  as the unit of processing, not graphemes. 
  """
  require Logger

  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Binary
  alias Exa.Convert

  @typedoc "Error when strings are not equal."
  @type mismatch() ::
          {:neq, index :: E.index0(), char11 :: char(), char2 :: char()}
          | {:len, excess1 :: String.t(), excess2 :: String.t()}

  @doc """
  Convert a single Unicode codepoint character (integer) to a String.

  Equivalent to `IO.charlist_to_string([c])`.

  ## Examples:
      iex> chr(0xB0)
      "°"
  """
  @spec chr(char()) :: String.t()
  def chr(c) when is_char(c), do: <<c::utf8>>

  @doc """
  Convert a Unicode codepoint character (integer) to a list of UTF8 bytes.

  ## Examples:
      iex> utf8_bytes(0xB0)
      [0xC2, 0xB0]
  """
  @spec utf8_bytes(char()) :: [byte()]
  def utf8_bytes(c) when is_char(c), do: c |> chr() |> Binary.to_bytes()

  @doc """
  Convert a Unicode integer to a list of UTF8 bytes,
  each encoded as a 2-character hex string.

  ## Examples:
      iex> utf8_hexs(0xB0)
      ["C2", "B0"]
  """
  @spec utf8_hexs(char()) :: [String.t()]
  def utf8_hexs(c) when is_char(c), do: c |> utf8_bytes() |> Enum.map(&Convert.b2h/1)

  @doc """
  Convert a Unicode codepoint character (integer) 
  to a zero-padded hex String representing the UTF8 bytes.
  The result will be zero-padded to have 
  an even number of hex characters.

  ## Examples:
      iex> utf8_hex(0xB0)
      "C2B0"
  """
  @spec utf8_hex(char()) :: String.t()
  def utf8_hex(c) when is_char(c), do: c |> utf8_hexs() |> Enum.join()

  @doc """
  Convert a Unicode integer to a list of UTF bytes,
  each encoded as a 2-character hex string,
  delimited by '%' for use in an escaped URL.

  ## Examples:
      iex> utf8_uri(0xB0)
      "%C2%B0"
  """
  @spec utf8_uri(char()) :: String.t()
  def utf8_uri(c) when is_char(c) do
    c |> utf8_hexs() |> Enum.map(fn h -> <<?%, h::binary>> end) |> Enum.join()
  end

  @doc """
  Patch and debug non-UTF8 sequences in binary data.

  If a bad character is encountered:
  - Log an error message: line and column number, 
    then the line itself up to the bad value.
  - Change the bad byte to the provided replacement character.
  - Continue parsing...

  The default replacement character is '*'
  so that a corrupted ASCII file remains ASCII
  (e.g. ISO-8859-1 English text with a few accented characters).
  You may want to pass the Unicode replacement character 0xFFFD
  if you know that downstrean processing tools can handle Unicode.
  """
  @spec patch_utf8(binary(), char() | String.t()) :: String.t()
  def patch_utf8(bin, rc \\ ?*) when is_binary(bin) do
    rc =
      cond do
        is_char(rc) -> chr(rc)
        is_string(rc) -> rc
      end

    do_utf8(bin, 1, 0, <<>>, rc, <<>>, 0)
  end

  defp do_utf8(<<?\n, rest::binary>>, lin, _col, _line, rc, buf, nerr) do
    do_utf8(rest, lin + 1, 0, <<>>, rc, <<buf::binary, ?\n>>, nerr)
  end

  defp do_utf8(<<c::utf8, rest::binary>>, lin, col, line, rc, buf, nerr) do
    do_utf8(rest, lin, col + 1, <<line::binary, c::utf8>>, rc, <<buf::binary, c::utf8>>, nerr)
  end

  defp do_utf8(<<i, rest::binary>>, lin, col, line, rc, buf, nerr) do
    # could be various issues here: 
    # single byte error, or illegal byte sequence
    # just report single bytes for now
    Logger.error("UTF8 byte [#{lin},#{col + 1}]: illegal value 0x#{int_hex(i)}")
    Logger.error(line)
    Logger.error(String.duplicate(" ", col) <> "^")
    newlin = <<line::binary, rc::binary>>
    newbuf = <<buf::binary, rc::binary>>
    do_utf8(rest, lin, col + 1, newlin, rc, newbuf, nerr + 1)
  end

  defp do_utf8(<<>>, _, _, _, _, buf, 0), do: buf

  defp do_utf8(<<>>, _, _, _, rc, buf, nerr) do
    Logger.error("Found #{nerr} errors, continuing with replacement character #{rc} ...")
    buf
  end

  @doc """
  Convert an unsigned (non-negative) integer to a hex String.

  The result will be zero-padded to have 
  an even number of hex characters.

  ## Examples:
      iex> int_hex(0x0A)
      "0A"
      iex> int_hex(0xC2B0)
      "C2B0"
  """
  @spec int_hex(non_neg_integer()) :: String.t()
  def int_hex(i) do
    str = Integer.to_string(i, 16)
    if str |> String.length() |> is_even(), do: str, else: "0" <> str
  end

  @doc """
  Get the last grapheme in a string and the index in one pass.

  If the string is empty, return `{nil, -1}`.

  Equivalent to `{String.last(str), String.length(str)-1}`.

  ## Examples: 
      iex> last_grapheme("")
      {nil, -1}
      iex> last_grapheme("b")
      {"b", 0}
      iex> last_grapheme("bar")
      {"r", 2}
  """
  @spec last_grapheme(String.t()) :: {String.grapheme(), -1 | E.index0()}
  def last_grapheme(""), do: {nil, -1}
  def last_grapheme(str), do: lastg(String.next_grapheme(str), 0)

  defp lastg({gr, ""}, i), do: {gr, i}
  defp lastg({_, rest}, i), do: lastg(String.next_grapheme(rest), i + 1)

  @doc """
  Get the last index in a string.

  If the string is empty, return `-1`.

  Equivalent to `String.length(str) - 1`.

  ## Examples: 
      iex> last_index("")
      -1
      iex> last_index("b")
      0
      iex> last_index("bar")
      2
  """
  @spec last_index(String.t()) :: -1 | E.index0()
  def last_index(""), do: -1
  def last_index(str), do: lasti(String.next_grapheme(str), 0)

  defp lasti({_, ""}, i), do: i
  defp lasti({_, rest}, i), do: lasti(String.next_grapheme(rest), i + 1)

  @doc """
  Get the grapheme at an index.

  If the index is beyond the length of the string,
  then return the remaining index for the next string.

  If the index is greater than or equal to the length,
  return target index minus string length.

  If the string is empty, return the index unchanged..

  Equivalent to the following, 
  but without using `String.length` or `String.at` O(n) functions:

  ```
  case String.length(str) do
    len when i < len -> String.at(str)
    len -> i - len
  end
  ```

  ## Examples: 
      iex> grapheme("", 99)
      99
      iex> grapheme("bar", 0)
      "b"
      iex> grapheme("bar", 2)
      "r"
      iex> grapheme("bar", 5)
      2
  """
  @spec grapheme(String.t(), E.index0()) :: String.grapheme() | E.index0()
  def grapheme("", i), do: i
  def grapheme(str, i), do: gr(String.next_grapheme(str), i)

  defp gr(nil, i), do: i
  defp gr({gr, _}, 0), do: gr
  defp gr({_, rest}, i), do: gr(String.next_grapheme(rest), i - 1)

  @doc """
  Delete a grapheme at an index in a non-empty string.

  Raises MatchError if the string is empty or the index is out of range.

  ## Examples: 
      iex> delete_grapheme("a", 0)
      ""
      iex> delete_grapheme("bar", 0)
      "ar"
      iex> delete_grapheme("bar", 1)
      "br"
      iex> delete_grapheme("bar", 2)
      "ba"
  """
  @spec delete_grapheme(String.t(), E.index0()) :: String.t()
  def delete_grapheme(str, 0) when str != "", do: str |> String.next_grapheme() |> elem(1)

  def delete_grapheme(str, i) when is_string(str) and is_index1(i) do
    {pre, istr} = String.split_at(str, i)
    # MatchError if index out of range
    # if i >= String.length(str), then istr == "", next gives nil
    {_gr, post} = String.next_grapheme(istr)
    pre <> post
  end

  @doc """
  Insert a grapheme or single character at an index in a string.

  If the index is equal to 0, the new element will be 
  inserted at the beginning of the string.

  If the index is greater than or equal to the length of the string, 
  the new element will be inserted at the end of the string.

  ## Example
      iex> insert("abc", ?z, 0)
      "zabc"
      iex> insert("abc", ?z, 1)
      "azbc"
      iex> insert("abc", ?z, 99)
      "abcz"
  """
  @spec insert(String.t(), String.grapheme() | char(), E.index0()) :: String.t()
  def insert(str, c, i) when is_char(c), do: insert(str, <<c::utf8>>, i)
  def insert("", gr, _) when is_string(gr), do: gr

  def insert(str, gr, i) when is_string(gr) and is_index0(i) do
    cond do
      i == 0 ->
        <<gr::binary, str::binary>>

      i >= String.length(str) ->
        <<str::binary, gr::binary>>

      true ->
        {pre, post} = String.split_at(str, i)
        <<pre::binary, gr::binary, post::binary>>
    end
  end

  @doc "Downcase an ASCII character."
  @spec downcase(char()) :: char()
  def downcase(c) when is_upper(c), do: c - ?A + ?a
  def downcase(c) when is_ascii(c), do: c

  @doc "Upcase an ASCII character."
  @spec upcase(char()) :: char()
  def upcase(c) when is_lower(c), do: c - ?a + ?A
  def upcase(c) when is_ascii(c), do: c

  @doc """
  Compare two Strings for equality of characters (not graphemes).

  Return `:eq` or details of the first characters that do not match.

  There are two sources of inequality:
  - corresponding characters are not equal
  - length mismatch:
    - first string has additional characters
    - second string has additional characters

  ## Examples:
      iex> compare("abc","abc")
      :eq
      iex> compare("azc","abc")
      {:neq, 1, ?z, ?b}
      iex> compare("abcd","abc")
      {:len, "d", ""}
      iex> compare("abc","abcz")
      {:len, "", "z"}
  """
  @spec compare(String.t(), String.t()) :: :eq | mismatch()
  def compare(xstr, ystr), do: cmp(xstr, ystr, 0)

  @spec cmp(String.t(), String.t(), E.index0()) :: :eq | mismatch()
  defp cmp(<<c::utf8, r1::binary>>, <<c::utf8, r2::binary>>, i), do: cmp(r1, r2, i + 1)
  defp cmp(<<c1::utf8, _::binary>>, <<c2::utf8, _::binary>>, i), do: {:neq, i, c1, c2}
  defp cmp(<<>>, <<>>, _), do: :eq
  defp cmp(s1, <<>>, _), do: {:len, s1, ""}
  defp cmp(<<>>, s2, _), do: {:len, "", s2}

  @doc "Convert String mismatch results to error strings."
  @spec mismatch(:eq | mismatch()) :: String.t()
  def mismatch(:eq), do: "Equal"
  def mismatch({:neq, i, c1, c2}), do: "Error [#{i}]: #{c1} != #{c2}"
  def mismatch({:len, s1, ""}), do: "Error: excess 1st string\n#{s1}"
  def mismatch({:len, "", s2}), do: "Error: excess 2nd string\n#{s2}"

  @doc """
  Count the number of occurrences of a character in a string.
  If a charlist is input, then count occurrences of all the characters in the list.

  ## Examples
      iex> count( "11-17-2020", ?- )
      2
      iex> count( "11-17-2020 12:23:45", '-:' )
      4
  """
  @spec count(String.t(), char() | charlist()) :: E.count()
  def count(str, c) when is_string(str) and is_char(c), do: do_count(c, str, 0)
  def count(str, cs) when is_string(str) and is_list(cs), do: do_counts(cs, str, 0)

  defp do_count(c, <<c::utf8, rest::binary>>, n), do: do_count(c, rest, n + 1)
  defp do_count(c, <<_::utf8, rest::binary>>, n), do: do_count(c, rest, n)
  defp do_count(_, <<>>, n), do: n

  defp do_counts(cs, <<c::utf8, rest::binary>>, n) do
    cond do
      c in cs -> do_counts(cs, rest, n + 1)
      true -> do_counts(cs, rest, n)
    end
  end

  defp do_counts(_, <<>>, n), do: n

  @doc """
  Test if a string contains a specific character.

  Equivalent to `String.contains?( str, <<c::utf8>> )`

  ## Examples
      iex> contains?( "11-17-2020", ?- )
      true
      iex> contains?( "1/2", ?z )
      false
  """
  @spec contains?(String.t(), char()) :: bool()
  def contains?(str, c) when is_string(str) and is_char(c), do: do_contains(c, str)

  defp do_contains(c, <<c::utf8, _::binary>>), do: true
  defp do_contains(c, <<_::utf8, rest::binary>>), do: do_contains(c, rest)
  defp do_contains(_, <<>>), do: false

  @doc ~S"""
  Normalize whitespace. 

  Trim and convert all internal runs of (ASCII) whitespace to a single space.
  Equivalent to `str |> String.split() |> Enum.join(" ")`.

  ## Examples
      iex> normalize( "\n\nfoo  \t\tba   r\t\n" )
      " foo ba r "
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(str), do: norm(str, <<>>)

  defp norm(<<c, rest::binary>>, out) when is_ws(c), do: nows(rest, <<out::binary, ?\s>>)
  defp norm(<<c, rest::binary>>, out), do: norm(rest, <<out::binary, c>>)
  defp norm(<<>>, out), do: out

  defp nows(<<c, rest::binary>>, out) when is_ws(c), do: nows(rest, out)
  defp nows(<<c, rest::binary>>, out), do: norm(rest, <<out::binary, c>>)
  defp nows(<<>>, out), do: out

  @doc """
  Generate an ordinal (positive integer) formatted 
  according to a character flag.

  Ordinal indicators can be:
  - `'1'` decimal integers 
  - `'a'` lower-case Roman letters (limit 26)
  - `'A'` upper-case Roman letters (limit 26)
  - `'i'` lower-case Roman numerals
  - `'I'` upper-case Roman numerals

  ## Examples:
      iex> ordinal(3,?1)
      "3"
      iex> ordinal(3,?a)
      "c"
      iex> ordinal(26,?A)
      "Z"
      iex> ordinal(14,?i)
      "xiv"
      iex> ordinal(9,?I)
      "IX"
  """
  @spec ordinal(E.index1(), ?1 | ?a | ?A | ?i | ?I) :: String.t()
  def ordinal(i, ?1) when is_pos_int(i), do: Integer.to_string(i)
  def ordinal(i, ?a) when is_pos_int(i) and i <= 26, do: chr(?a + i - 1)
  def ordinal(i, ?A) when is_pos_int(i) and i <= 26, do: chr(?A + i - 1)
  def ordinal(i, ?i) when is_pos_int(i), do: String.downcase(roman("", i))
  def ordinal(i, ?I) when is_pos_int(i), do: roman("", i)

  defp roman(s, 0), do: s
  defp roman(s, 1), do: s <> "I"
  defp roman(s, 2), do: s |> roman(1) |> roman(1)
  defp roman(s, 3), do: s |> roman(1) |> roman(1) |> roman(1)
  defp roman(s, 4), do: s |> roman(1) |> roman(5)
  defp roman(s, 5), do: s <> "V"
  defp roman(s, i) when 5 < i and i < 9, do: s |> roman(5) |> roman(i - 5)
  defp roman(s, 9), do: s |> roman(1) |> roman(10)
  defp roman(s, 10), do: s <> "X"
  defp roman(s, i) when i > 10 and i < 40, do: s |> roman(10) |> roman(i - 10)
  defp roman(s, i) when i >= 40 and i < 50, do: s |> roman(10) |> roman(50) |> roman(i - 40)
  defp roman(s, 50), do: s <> "L"
  defp roman(s, i) when i > 50 and i < 90, do: s |> roman(50) |> roman(i - 50)
  defp roman(s, i) when i >= 90 and i < 100, do: s |> roman(10) |> roman(100) |> roman(i - 90)
  defp roman(s, 100), do: s <> "C"
  defp roman(s, i) when i > 100, do: s |> roman(100) |> roman(i - 100)

  @doc ~S"""
  Test if a string is filled with characters of a specified class.

  See Regex Character Class documntation for the list of allowed classes.
  The default class is whitespace: 'space'.
  The empty string always returns true.

  ## Examples
      iex> all_class?( "foo bar" )
      false
      iex> all_class?( "  \n \t " )
      true
      iex> all_class?( "" )
      true
  """
  @spec all_class?(String.t(), String.t()) :: bool()
  def all_class?(str, class \\ "space") when is_string(str) and is_string(class) do
    re = success!(Regex.compile("^([[:#{class}:]]*)$"))
    Regex.match?(re, str)
  end

  @doc ~S"""
  Test if a string has any characters of a specified class.

  See Regex Character Class documntation for the list of allowed classes.
  The default class is whitespace: 'space'.
  The empty string always returns false.

  ## Examples
      iex> any_class?( "foo bar" )
      true
      iex> any_class?( "foo bar", "digit" )
      false
      iex> any_class?( "abc 123", "alpha" )
      true
      iex> any_class?( "abc 123", "digit" )
      true
      iex> any_class?( "" )
      false
  """
  @spec any_class?(String.t(), String.t()) :: bool()
  def any_class?(str, class \\ "space") when is_string(str) and is_string(class) do
    re = success!(Regex.compile("[[:#{class}:]]"))
    Regex.match?(re, str)
  end

  @doc "Repeat a character to make a string."
  @spec repeat(char(), E.count()) :: String.t()
  def repeat(c, 0) when is_char(c), do: ""
  def repeat(c, n) when is_char(c) and is_pos_int(n), do: :binary.copy(<<c::utf8>>, n)

  @doc """
  Truncate a string to be a fixed width.
  If the string is longer than the width,
  then crop an additional 3 characters
  and add '...' at the end.
  The maximum width must be at least 4.
  """
  @spec summary(String.t(), E.count2()) :: String.t()
  def summary(str, n \\ 33) when is_string(str) and is_count2(n) and n > 3 do
    len = String.length(str)
    if len <= n, do: str, else: String.slice(str, 0..(n - 4)) <> "..."
  end

  @doc """
  Test if a string or charlist is a valid identifier.

  The definition is strict. 
  The name must start with a letter,
  then contain only letters, digits or '_' underscore.
  """
  @spec valid_identifier?(String.t() | charlist()) :: bool()

  def valid_identifier?(str) when is_nonempty_string(str) do
    str |> to_charlist() |> valid_identifier?()
  end

  def valid_identifier?([c | chars]) do
    chars != [] and is_alpha(c) and Enum.all?(chars, &is_namechar/1)
  end

  @doc """
  Test if a string or charlist is a valid name, 
  e.g. for a filename.

  The definition is loose. 
  The first character, and all the others,
  can be a letter, digit or '_' underscore.
  """
  @spec valid_name?(String.t() | charlist()) :: bool()

  def valid_name?(str) when is_nonempty_string(str) do
    str |> to_charlist() |> valid_name?()
  end

  def valid_name?(chars) when is_nonempty_list(chars) do
    chars != [] and Enum.all?(chars, &is_namechar/1)
  end

  @doc """
  Convert a general string to a valid filename or atom.

  Trim and convert all internal runs of whitespace to a single '_'.

  Optionally truncate the name at a maximum length.
  Passing `:infinity` will not truncate the string.
  The default `maxlen` is 250, which is just under the limit
  for files and atoms.

  If the name is being used for a file,
  the argument should not contain the '.' filetype suffix.
  The filetype should be added after validating the name.

  However, if the file is to be compressed, with filetype `.gz`,
  then it is acceptable to include the underlying filetype in the name.
  For example, using name `foo.txt` with filetype '.gz'
  making `foo.txt.gz`, allows the decompressed file to appear as `foo.txt`.
  """
  @spec sanitize!(String.t(), E.maybe(E.count1()), bool()) :: String.t()
  def sanitize!(str, maxlen \\ 250, allow_safe_file? \\ false)
      when is_binary(str) and (maxlen == nil or is_count1(maxlen)) do
    filter_fun = if allow_safe_file?, do: &is_filechar/1, else: &is_namechar/1

    chars =
      str
      |> String.split(~r{[[:space:]]+}, trim: true)
      |> Enum.join("_")
      |> String.to_charlist()
      |> Enum.filter(filter_fun)

    chars = if is_nil(maxlen), do: chars, else: Enum.take(chars, maxlen)

    if chars == [] do
      raise ArgumentError, message: "Name '#{str}' is not a valid name"
    end

    to_string(chars)
  end

  @doc """
  Replace any of the charlist characters, 
  with the replacement character.

    ## Examples
      iex> replace_any("", 'c1', ?_)
      ""
      iex> replace_any("abc123", '', ?_)
      "abc123"
      iex> replace_any("abc123", 'c1', ?_)
      "ab__23"
      iex> replace_any("abc3211x1yzc", 'c1', ?_)
      "ab_32__x_yz_"
  """
  @spec replace_any(String.t(), charlist(), char()) :: String.t()
  def replace_any(str, cs, r), do: do_replace(str, cs, r, <<>>)

  defp do_replace(str, [], _r, _), do: str

  defp do_replace(<<c::utf8, rest::binary>>, cs, r, out) do
    cond do
      c in cs -> do_replace(rest, cs, r, <<out::binary, r::utf8>>)
      true -> do_replace(rest, cs, r, <<out::binary, c::utf8>>)
    end
  end

  defp do_replace(<<>>, _cs, _r, out), do: out

  @doc "Convert a string to an atom by validating as a name."
  @spec to_atom(String.t(), E.maybe(pos_integer())) :: atom()
  def to_atom(str, maxlen \\ 200), do: str |> sanitize!(maxlen) |> String.to_atom()

  @doc ~S"""
  Escape a string with any occurrences of special characters.

  The specials argument should be charlist of characters.

  ## Examples
      iex> escape( "a+b?c*", '+?*' )
      ~S"a\+b\?c\*"
      iex> escape( "'a'", ~c(') )
      ~S"\'a\'"
      iex> escape( ~S"a\nb", '\\' )
      ~S"a\\nb"
  """
  @spec escape(String.t(), charlist()) :: String.t()
  def escape(str, specials) when is_string(str) and is_list(specials) do
    esc(str, specials, "")
  end

  @spec esc(String.t(), charlist(), String.t()) :: String.t()

  defp esc(<<c::utf8, rest::binary>>, cs, out) do
    cond do
      c in cs -> esc(rest, cs, <<out::binary, ?\\, c::utf8>>)
      true -> esc(rest, cs, <<out::binary, c::utf8>>)
    end
  end

  defp esc(<<>>, _cs, out), do: out

  # The special characters that need escaping in the body of a regex.
  # Does not include '-' for inside character classes.
  # Does not include '\' used to specify character classes ??
  @regex_specials ~c"+|*^.$?()[{"

  @doc "Escape character literals for use in a regex."
  @spec escape_regex(String.t()) :: String.t()
  def escape_regex(str) when is_string(str), do: escape(str, @regex_specials)

  @doc ~S"""
  Parse a string using a regex.
  Just reverses `Regex.run` for use in string pipes.
  ## Examples
      iex> "11-17-2020" |> parse( ~r"(\d+)-(\d+)-(\d+)" )
      ["11-17-2020" ,"11","17","2020"]
  """
  @spec parse(String.t(), Regex.t()) :: [String.t()]
  def parse(str, regex) when is_string(str), do: Regex.run(regex, str)

  @doc """
  Wrap a string in open and close delimiters.

  Suitable for String piping from Enum.join.

  Default open/close is double quote.

  ## Examples
      iex> "abc" |> wraps 
      "\\"abc\\""
      iex> "(abc)" |> wraps("(",")")
      "((abc))"
      iex> [:a,:b,:c] |> Enum.join(", ") |> wraps("< "," >")
      "< a, b, c >"
  """
  @spec wraps(String.t(), String.t(), String.t()) :: String.t()
  def wraps(str, open \\ "\"", close \\ "\"") do
    open <> str <> close
  end

  @doc """
  Ensure a string is wrapped in open and close delimiters.
  New delimiters are not added if the string 
  already has them as prefix and suffix.

  Suitable for String piping from Enum.join.

  Default open/close is double quote.

  ## Examples
      iex> "abc" |> ensure_wraps 
      "\\"abc\\""
      iex> "(abc)" |> ensure_wraps("(",")")
      "(abc)"
      iex> [:a,:b,:c] |> Enum.join(", ") |> ensure_wraps("< "," >")
      "< a, b, c >"
  """
  @spec ensure_wraps(String.t(), String.t(), String.t()) :: String.t()
  def ensure_wraps(str, open \\ "\"", close \\ "\"") do
    str |> ensure_prefix(open) |> ensure_suffix(close)
  end

  @doc "Ensure a string begins with a specific prefix."
  @spec ensure_prefix(String.t(), String.t()) :: String.t()
  def ensure_prefix(str, pre) do
    if String.starts_with?(str, pre), do: str, else: pre <> str
  end

  @doc "Ensure a string ends with a specific suffix."
  @spec ensure_suffix(String.t(), String.t()) :: String.t()
  def ensure_suffix(str, suf) do
    if String.ends_with?(str, suf), do: str, else: str <> suf
  end

  @doc """
  Unwrap a string by removing open and close delimiters.
  Suitable for String piping from `Enum.join`.

  Default open/close is double quote,
  so it behaves like an unquote function.
  If the prefix/suffix does not equal the open/close,
  then it is ignored, and that end of the string is not changed.

  ## Examples
      iex> "\\"abc\\"" |> unwraps
      "abc"
      iex> "<abc>" |> unwraps("<",">")
      "abc"
      iex> "[abc]" |> unwraps("<",">")
      "[abc]"
  """
  @spec unwraps(String.t(), String.t(), String.t()) :: String.t()
  def unwraps(str, open \\ "\"", close \\ "\"")
      when is_string(str) and is_string(open) and is_string(close) do
    str |> String.replace_prefix(open, "") |> String.replace_suffix(close, "")
  end

  @doc """
  Split text into lines with a maximum length.
  Break lines at whitespace boundaries. 

  Reform the lines with a single space replacing 
  internal runs of whitespace (normalization).

  The `maxlen` line length must be larger 
  than the longest word token in the input string.
  So do _not_ use this function for encoded binaries
  (e.g. base64 or ascii85).

  ## Examples
      iex> lines("Lorem ipsum dolor sit amet, consectetur", 12)
      ["Lorem ipsum", "dolor sit", "amet,", "consectetur"]
  """
  @spec lines(String.t(), E.count1()) :: [String.t()]
  def lines(str, maxlen) when is_string(str) and is_count1(maxlen) do
    str
    |> String.split()
    |> Exa.List.take_all_while(0, fn s, len ->
      new_len = len + String.length(s) + 1
      {new_len <= maxlen, new_len}
    end)
    |> Enum.map(&Enum.join(&1, " "))
  end

  # custom rendering of functions??
  defimpl String.Chars, for: Function do
    def to_string(fun), do: elem(Function.info(fun, :name), 1)
  end
end

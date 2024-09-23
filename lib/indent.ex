defmodule Exa.Indent do
  @moduledoc """
  Utilities for indentable text output.
  """
  require Logger
  import Exa.String

  import Exa.Types
  alias Exa.Types, as: E

  import Exa.Text
  alias Exa.Text, as: T
  alias Exa.Text

  # import Exa.Font.Types
  # alias Exa.Font.Symbol

  # Implementation notes:

  # The text is textdata, 
  # but allowing the empty list to represent empty value (not "").
  # The textdata is built in 'pivoted' format:
  #  - strings are stored in normal forward order
  #  - lists are reversed, and deep lists are reversed all the way down
  #  - new values are pre-pended onto the front of the text
  #  - new list values are pivoted before being pre-pended [text_pivot(v)|text]
  #  - new strings are not reversed [str|text]
  #  - final output must be done through to_text or to_string
  #    not direct access to the field using indent.text or Map.fetch!(indent,:text)
  #  - final access un-pivots the deeply nested lists, but does not reverse strings

  # The ws whitespace list behaves like a stack with a special protected last element.
  # The ws stack is either:
  #   - just the singleton fixed margin string, or
  #   - textlist containing tab strings, followed by the margin string.
  # The ws stack is never the empty list.
  # If there is no margin specified, then the margin string is the empty string.
  # Empty strings are always removed from output.

  # Push just prepends tabs to the front of the ws list.
  # Pop will remove the head tab from the ws list,
  # but only two or more elements are present.
  # If just the margin string is present,
  # then pop does not change the whitespace.

  # table delimiters ----------

  @typedoc """
  Table delimiters are defined by:
  - a horizontal separator, repeated in rows between table sections
  - a vertical separator, used to separate columns 
  - nine corners 'L', column boundaries 'T' and central cross '+' in the order:
      top row: top-left corner L, top-middle T, top-right corner L
      mid row: mid-left T, mid-middle cross +, mid-right T
      bottom row: bottom-left corner L, bottom-middle T, bottom-right corner L
  """
  @type table_delims() :: {
          hchar :: char(),
          vchar :: char(),
          {
            {tl :: char(), tm :: char(), tr :: char()},
            {ml :: char(), mm :: char(), mr :: char()},
            {bl :: char(), bm :: char(), br :: char()}
          }
        }

  # access one of the inner tuples
  defp l({l, _, _}), do: l
  defp m({_, m, _}), do: m
  defp r({_, _, r}), do: r

  @ascii_delims {?-, ?|,
                 {
                   {?+, ?+, ?+},
                   {?+, ?+, ?+},
                   {?+, ?+, ?+}
                 }}

  @light_delims {0x2500, 0x2502,
                 {
                   {0x250C, 0x252C, 0x2510},
                   {0x251C, 0x253C, 0x2524},
                   {0x2514, 0x2534, 0x2518}
                 }}

  @heavy_delims {0x2501, 0x2503,
                 {
                   {0x250F, 0x2533, 0x2513},
                   {0x2523, 0x254B, 0x252B},
                   {0x2517, 0x253B, 0x251B}
                 }}

  @light_horiz_delims {0x2500, ?\s,
                       {
                         {0x2500, 0x2500, 0x2500},
                         {0x2500, 0x2500, 0x2500},
                         {0x2500, 0x2500, 0x2500}
                       }}

  @heavy_horiz_delims {0x2501, ?\s,
                       {
                         {0x2501, 0x2501, 0x2501},
                         {0x2501, 0x2501, 0x2501},
                         {0x2501, 0x2501, 0x2501}
                       }}

  def ascii_delims(), do: @ascii_delims
  def light_delims(), do: @light_delims
  def heavy_delims(), do: @heavy_delims
  def light_horiz_delims(), do: @light_horiz_delims
  def heavy_horiz_delims(), do: @heavy_horiz_delims

  # vertical delimiters 
  # to trim from a valid row
  @spec row_delims() :: charlist()
  def row_delims() do
    [@ascii_delims, @light_delims, @heavy_delims] |> Enum.map(&elem(&1, 1))
  end

  # leading spacer characters 
  # to indicate a spacer to be removed
  @spec space_delims() :: charlist()
  def space_delims() do
    [
      @ascii_delims,
      @light_delims,
      @heavy_delims,
      @light_horiz_delims,
      @heavy_horiz_delims
    ]
    |> Enum.map(&elem(&1, 2))
    |> Enum.reduce(MapSet.new(), fn tup3, cs ->
      Exa.Tuple.reduce(tup3, cs, fn tup, cs -> MapSet.put(cs, elem(tup, 0)) end)
    end)
    |> MapSet.to_list()
  end

  @typedoc "An end-of-line specifier for right-adjusted border."
  @type endspec() :: {width :: E.count1(), suffix :: String.t()}

  # indent type ----------

  defmodule Indent do
    defstruct text: [], ws: [""], tab: "  ", table: nil, endl: nil, line: 1, col: 0
  end

  @type t :: %Indent{}

  @type indent() :: %Indent{
          text: [] | T.textdata(),
          ws: T.textlist(),
          tab: String.t(),
          table: table_delims(),
          endl: nil | endspec(),
          line: E.count1(),
          col: E.count()
        }

  # either use this guard or the pattern match %Indent{}=io
  defguard is_indent(io) when is_struct(io, Indent)

  @typedoc "Horizontal alignment for fixed width fields."
  @type align :: :left | :right
  defguard is_align(al) when al == :left or al == :right

  @typedoc "Specify a fixed string or a number of spaces."
  @type spacer :: E.count() | String.t()
  defguard is_spacer(spc) when is_count(spc) or is_string(spc)

  # constructor ----------

  @doc """
  Constructor for indentable text.

  The margin is a fixed initial indent for every line.

  The tab is an additional indent for each pushed level.

  The margin and tab can either be a string literal or a number of spaces.

  The table delimiters specify the characters to draw tables.
  See the type doc for more information.

  The initial textdata is not processed in any way,
  in particular, existing newlines do not have margins added.
  However, the initial text is analyzed to create the 
  initial line number and column position.
  Note it is `textdata` not just `textlist`, so a String is a valid argument.
  """
  @spec indent(spacer(), spacer(), table_delims(), T.textdata()) :: indent()
  def indent(tab \\ 2, margin \\ 0, delims \\ @light_delims, text \\ [])
      when is_spacer(margin) and is_spacer(tab) and is_tuple(delims) and is_textdata(text) do
    {lin, col} = text_line_col(text)

    %Indent{
      text: text,
      ws: [spacer(margin)],
      tab: spacer(tab),
      table: delims,
      endl: nil,
      line: lin,
      col: col
    }
  end

  # to_string protocol ----------

  defimpl String.Chars, for: Exa.Indent.Indent do
    def to_string(%Indent{} = ind), do: ind |> Exa.Indent.to_text() |> Kernel.to_string()
  end

  @doc "Get the deeply nested text data."
  @spec to_text(%Indent{}) :: T.textdata()
  def to_text(%Indent{text: str}) when is_string(str), do: str
  def to_text(%Indent{text: text}) when is_list(text), do: text_pivot(text)

  # reduce ----------

  @doc "Reverse reduce arguments to allow piping."
  @spec reduce(indent(), Enumerable.t(), (any(), indent() -> indent())) :: indent()
  def reduce(io, xs, fun), do: Enum.reduce(xs, io, fun)

  # access functions----------

  @doc "Get the current line number and column position."
  @spec line_col(indent()) :: T.textpos()
  def line_col(io) when is_indent(io), do: {io.line, io.col}

  @doc "Get the current width of leading margin and tabs."
  @spec lead(indent()) :: E.count()
  def lead(%Indent{ws: ws}), do: ws |> List.flatten() |> length()

  @doc "Set the end-of-line specification."
  @spec set_endl(indent(), E.count1(), String.t()) :: indent()
  def set_endl(%Indent{} = io, width, suffix) when is_count1(width) and is_string(suffix) do
    %Indent{io | endl: {width, suffix}}
  end

  # stack operations ----------

  @doc "Increase the indent level."
  @spec push(indent(), E.count()) :: indent()
  def push(io, n \\ 1)
  def push(io, 0), do: io
  def push(%Indent{tab: ""} = io, n), do: io |> push(n - 1)
  def push(%Indent{tab: tab, ws: ws} = io, n), do: %{io | ws: [tab | ws]} |> push(n - 1)

  @doc "End line, increase indent lavel, and start new line."
  @spec pushl(indent(), E.count()) :: indent()
  def pushl(io, n \\ 1), do: io |> endl() |> push(n) |> newl()

  @doc """
  Reduce the indent level.
  It is not an error if there are no more tabs remaining.
  The margin will always be preserved.
  """
  @spec pop(indent(), E.count()) :: indent()
  def pop(io, n \\ 1)
  def pop(io, 0), do: io
  def pop(%Indent{tab: ""} = io, n), do: io |> pop(n - 1)
  def pop(%Indent{ws: [_]} = io, n), do: io |> pop(n - 1)
  def pop(%Indent{ws: [_ | ws]} = io, n), do: %{io | ws: ws} |> pop(n - 1)

  @doc "End line, decrease indent level, and start new line."
  @spec popl(indent(), E.count()) :: indent()
  def popl(io, n \\ 1), do: io |> endl() |> pop(n) |> newl()

  # append operations ----------

  @doc "Append a single space to the text."
  @spec sp(indent()) :: indent()
  def sp(io) when is_indent(io), do: chr(io, ?\s)

  @doc """
  Append a single character to the text.
  Use `newl/1` or 'newl/2' to get an indent before using this direct output.
  """
  @spec chr(indent(), char()) :: indent()

  def chr(%Indent{text: text, line: line} = io, ?\n) do
    %{io | text: [?\n | text], line: line + 1, col: 0}
  end

  def chr(%Indent{text: text, col: col} = io, c) when is_char(c) do
    %{io | text: [c | text], col: col + 1}
  end

  # @doc """
  # Append a single character LaTeX symbol to the text.

  # The symbols are atoms representing LaTeX escapes.
  # For example, LaTeX `\\exists` uses atom `:exists`.
  # If the escape is not recognized, 
  # the Unicode Replacement Character (0xFFFD) is used.
  # """
  # @spec sym(indent(), F.symbol()) :: indent()
  # def sym(%Indent{} = io, sym) when is_symbol(sym) do
  #   chr(io, sym |> Symbol.lookup() |> elem(1))
  # end

  # @doc """
  # Append a LaTeX sequence to the text.
  # The input must be a string enclosed in dollar signs: `$....$`.

  # The content may include normal characters 
  # and LaTeX escapes, e.g. `\\exists`.
  # The escape conversion is entirely linear, 
  # there is no typesetting.
  # """
  # @spec latex(indent(), String.t()) :: indent()
  # def latex(%Indent{} = io, latex) when is_string(latex) do
  #   txt(io, Symbol.latex(latex))
  # end

  @doc """
  Append any term to the text.
  Use `newl/1` to get an indent before using this direct output.
  An integer is converted as a number, not as a raw character.
  Terms are converted to a String using the `String.Chars` protocol.
  It is an error if the type does not support `to_string/1`.
  Equivalent to: `txt( to_string(a) )`
  The argument should not include newlines.
  The argument is not processed in any way,
  in particular, existing newlines are not removed 
  and they do not have margins and tabs added.
  """
  @spec str(indent(), any()) :: indent()
  def str(%Indent{} = io, a), do: txt(io, Text.term_to_text(a))

  @doc """
  Append any term to the text and adjust to a fixed width.
  See `str/2` for conversion of terms to text.
  If the string conversion is shorter than the width,
  then padding spaces are added at the end opposite the alignment.
  If the string conversion is longer than the assigned width,
  then it is truncated at the end opposite the alignment.
  """
  @spec str(indent(), any(), E.count1(), align()) :: indent()
  def str(%Indent{} = io, a, width, align \\ :left)
      when is_int_pos(width) and is_align(align) do
    str = to_string(a)
    len = String.length(str)

    fix =
      cond do
        len == width -> str
        len < width and align == :left -> [str, spacer(width - len)]
        len < width and align == :right -> [spacer(width - len), str]
        # TODO: implement take_first / drop_last for textdata
        # TODO: break on whitespace
        len > width and align == :left -> String.slice(str, 0..(width - 1))
        len > width and align == :right -> String.slice(str, (len - width)..(len - 1))
      end

    txt(io, fix)
  end

  @doc """
  Append raw `textdata` to the text.
  Use `newl/1` to get an indent before using this direct output.
  Note it is `textdata` not just `textlist`, so a String is a valid argument.

  The argument should not include newlines.
  The argument is not processed in any way,
  in particular, existing newlines are not removed 
  and they do not have margins and tabs added.
  """
  @spec txt(indent(), char() | T.textdata()) :: indent()
  def txt(%Indent{} = io, ""), do: io
  def txt(%Indent{} = io, []), do: io

  def txt(%Indent{text: text, col: col} = io, txt) do
    # assert txt does not contain newline?
    # false = text_contains?( txt, ?\n )
    %{io | text: [text_pivot(txt) | text], col: col + text_length(txt)}
  end

  @doc """
  Append raw `textdata` to the text and adjust to a fixed width.
  If the text length is shorter than the width,
  then padding spaces are added at the end opposite the alignment.
  If the text length is longer than the assigned width,
  then it is truncated at the end opposite the alignment.
  """
  @spec txt(indent(), char() | T.textdata(), E.count1(), align()) :: indent()
  def txt(%Indent{} = io, txt, width, align \\ :left)
      when is_int_pos(width) and is_align(align) do
    len = text_length(txt)

    fix =
      cond do
        len == width ->
          txt

        len < width and align == :left ->
          [txt, spacer(width - len)]

        len < width and align == :right ->
          [spacer(width - len), txt]

        # these will never be raw char, so text_to_string is valid...
        len > width and align == :left ->
          txt |> text_to_string() |> String.slice(0..(width - 1))

        len > width and align == :right ->
          txt |> text_to_string() |> String.slice((len - width)..(len - 1))
      end

    txt(io, fix)
  end

  @doc """
  Append a newline to the text.
  Use `newl/1` to get indent and output before this line terminator.
  The same effect as `line/1`,
  but this version is meant to indicate the end of the current line,
  which already has an indent and some text output.

  If the Indent has an end specification, 
  padding and a final border suffix added.
  """
  @spec endl(indent()) :: indent()
  def endl(%Indent{endl: nil} = io), do: do_endl(io)
  def endl(%Indent{endl: {width, suffix}} = io), do: endl(io, width, suffix)

  @doc """
  Pad the line with a right-aligned suffix and then a newline.
  """
  @spec endl(indent(), E.count1(), T.textdata()) :: indent()
  def endl(%Indent{col: col} = io, width, suffix) do
    if width - col < 1, do: Logger.warning("Line exceeds allowed width")
    # subtract suffix length here?
    io |> txt(suffix, max(1, width - col), :right) |> do_endl()
  end

  defp do_endl(%Indent{text: text, line: lin} = io) do
    %{io | text: [?\n | text], line: lin + 1, col: 0}
  end

  @doc """
  Append an indent at the beginning of a line.
  The indent will be the margin plus all the current tab levels.
  """
  @spec newl(indent()) :: indent()
  def newl(%Indent{ws: [""]} = io), do: io

  def newl(%Indent{ws: ws, text: text, col: col} = io) do
    %{io | text: [ws | text], col: col + text_length(ws)}
  end

  @doc """
  Append a newline to the text.
  The same effect as `endl/1`,
  but this is meant to follow `endl/1` or another `line/1` 
  to indicate a completely empty line.

  Note that `newl/1` and `endl/1` are not invoked,
  so no margin strings, tab strings or suffix border appears.
  If you need framework strings, use `io |> newl() |> endl()`.
  """
  @spec line(indent()) :: indent()
  def line(io), do: do_endl(io)

  @doc """
  Append multiple completely empty lines.
  Equivalent to invoking 'line/1' multiple times.
  """
  @spec lines(indent(), E.count1()) :: indent()
  def lines(%Indent{} = io, 0), do: io

  def lines(%Indent{text: text, line: lin} = io, n) when is_count1(n) do
    %{io | text: [List.duplicate(?\n, n) | text], line: lin + n, col: 0}
  end

  @doc """
  Append a complete line, containing indent, term output and newline.
  See `str/2` for conversion of terms to text.
  A string argument should not contain newlines.
  Equivalent to `newl |> str(a) |> endl`.
  """
  @spec strl(indent(), any()) :: indent()
  def strl(%Indent{} = io, a), do: txtl(io, Text.term_to_text(a))

  @doc """
  Append a complete line, containing indent, text output and newline.
  Equivalent to `newl |> txt(a) |> endl`.
  """
  @spec txtl(indent(), T.textdata()) :: indent()
  def txtl(%Indent{text: text, ws: ws, line: lin} = io, txt) do
    %{io | text: [?\n, text_pivot(txt), ws | text], line: lin + 1, col: 0}
  end

  @doc """
  Append each element of a collection on a separate line.
  See `str/2` for conversion of terms to text.
  Suitable for text piping.
  """
  @spec strls(indent(), Enumerable.t()) :: indent()
  def strls(%Indent{} = io, coll), do: Enum.reduce(coll, io, &strl(&2, &1))

  @doc """
  Append each element of a collection on a separate line.
  See `txt/2` for conversion of terms to text.
  Text will not be quoted.
  Suitable for text piping.
  """
  @spec txtls(indent(), Enumerable.t()) :: indent()
  def txtls(%Indent{} = io, coll), do: Enum.reduce(coll, io, &txtl(&2, &1))

  @doc """
  Map a text-generating function over a collection,
  putting each result on a separate line.
  The function should pass through the indentable io argument.
  This version expects `textdata` for each line.
  The text should not contain newlines.
  The mapping function is passed the indentable object and the element.
  Suitable for text piping.
  """
  @spec txtfunls(indent(), Enumerable.t(a), (a -> T.textdata())) :: indent() when a: var
  def txtfunls(%Indent{} = io, coll, txtfun) when is_function(txtfun, 1) do
    Enum.reduce(coll, io, fn a, io -> io |> txtl(txtfun.(a)) end)
  end

  # ---------------
  # Table functions
  # ---------------

  # TODO: pass through alignment flags for each column

  @typedoc """
  A table spec is a number of columns and constant width, 
  or a list of column widths.
  """
  @type tspec() :: {E.count1(), E.count1()} | [E.count1(), ...]

  @typedoc "A row spec is a constant width, or a list of column widths."
  @type rspec() :: E.count1() | [E.count1(), ...]
  defguard is_rspec(rspec) when is_int_pos(rspec) or is_list_nonempty(rspec)

  @doc """
  Append a table with column headings and row data.
  Allow local override of global table delimiters.
  """
  @spec table(indent(), [...], [[...]], rspec(), E.maybe(table_delims())) :: indent()
  def table(io, cols, data, rspec, delims \\ nil)
      when is_indent(io) and
             is_list_nonempty(cols) and is_list_nonempty(data) and
             is_rspec(rspec) and (is_nil(delims) or is_tuple(delims)) do
    ncol = length(cols)
    delims = if is_nil(delims), do: io.table, else: delims
    # must be data to fill all columns
    true = Enum.all?(data, fn d -> ncol == length(d) end)

    tspec =
      if is_integer(rspec) do
        # regular table spec
        {ncol, rspec}
      else
        # number of widths must match number of columns 
        ^ncol = length(rspec)
        rspec
      end

    {hchar, vchar, {tdels, mdels, bdels}} = delims

    # write 3-row header structure with column names
    io =
      io
      |> sep(tspec, hchar, tdels)
      |> row(cols, rspec, vchar)
      |> sep(tspec, hchar, mdels)

    # write all the data rows and final separator
    data
    |> Enum.reduce(io, fn dat, io -> io |> row(dat, rspec, vchar) end)
    |> sep(tspec, hchar, bdels)
  end

  @doc """
  Append a horizontal line separator 
  using the default Indent table delimiters.

  The position is `:top`, `:middle` or `:bottom`.

  A horizontal fill character is repeated across each column.
  A delimiter text is inserted at each column boundary.

  The column widths can be a number of fixed values (tuple), 
  or an exlicit list of widths.

  There must be at least one column.

  The column widths must be greater than zero.
  """
  @spec sep(indent(), :top | :middle | :bottom, tspec()) :: indent()

  def sep(%Indent{table: delims} = io, :top, tspec) do
    {hchar, _vchar, {tdels, _mdels, _bdels}} = delims
    sep(io, tspec, hchar, tdels, false)
  end

  def sep(%Indent{table: delims} = io, :middle, tspec) do
    {hchar, _vchar, {_tdels, mdels, _bdels}} = delims
    sep(io, tspec, hchar, mdels, false)
  end

  def sep(%Indent{table: delims} = io, :bottom, tspec) do
    {hchar, _vchar, {_tdels, _mdels, bdels}} = delims
    sep(io, tspec, hchar, bdels, false)
  end

  # append a horizontal table separator.
  @spec sep(indent(), tspec(), char(), tuple(), bool()) :: indent()
  defp sep(io, tspec, hchar, dels, nl? \\ true)

  defp sep(io, {n, w}, hchar, dels, nl?)
       when is_int_pos(n) and is_int_pos(w) and is_tuple(dels) do
    hchars = repeat(hchar, w)
    col1 = <<l(dels)::utf8, hchars::binary>>
    mid = <<m(dels)::utf8, hchars::binary>>
    mids = List.duplicate(mid, n - 1)
    io = if nl?, do: newl(io), else: io
    io |> txt(col1) |> txt(mids) |> chr(r(dels)) |> do_endl
  end

  defp sep(io, [w1 | ws], hchar, dels, nl?) when is_list(ws) and is_tuple(dels) do
    # column widths must be greater than zero
    true = Enum.all?(ws, &(&1 > 0))
    io = if nl?, do: newl(io), else: io
    io = io |> chr(l(dels)) |> txt(repeat(hchar, w1))

    mid = m(dels)

    ws
    |> Enum.reduce(io, fn w, io -> io |> chr(mid) |> txt(repeat(hchar, w)) end)
    |> chr(r(dels))
    |> do_endl
  end

  @doc """
  Append a table data row.
  A delimiter text is inserted at each column boundary.
  The column widths can be a fixed value, or an explicit list of widths.
  There must be at least one column.
  The column widths must be greater than zero.
  The number of widths must match the number of data values.

  Only public for testing - don't use these directly.
  """
  @spec row(indent(), [...], rspec(), char()) :: indent()
  def row(io, dat, rspec, vchar)
      when is_indent(io) and is_list_nonempty(dat) and is_rspec(rspec) and is_char(vchar) do
    ws =
      if is_integer(rspec) do
        List.duplicate(rspec, length(dat))
      else
        # number of data values and column widths must match
        true = length(dat) == length(rspec)
        # column widths must be greater than zero
        true = Enum.all?(rspec, &(&1 > 0))
        rspec
      end

    Enum.zip(dat, ws)
    |> Enum.reduce(newl(io), fn {d, w}, io -> io |> chr(vchar) |> str(d, w) end)
    |> chr(vchar)
    |> do_endl
  end

  # -----------------
  # private functions
  # -----------------

  # Convert duplicates to string to save memory 
  # and speed up traversals, such as text_length.
  @spec spacer(spacer()) :: T.text()
  defp spacer(n) when is_int_nonneg(n), do: repeat(?\s, n)
  defp spacer(str) when is_string(str), do: str
end

defmodule Exa.Parse do
  @moduledoc """
  Utilities to parse simple data values,
  such as boolean, integer, float, date/times 
  and simple arrays of these types.

  The parsing functions can be used to read 
  CSV, JSON and i18n properties.

  The functions generate parsers, 
  so that they can be parametrized.

  The string arguments must be trimmed and tokenized,
  so the parser functions must consume 
  the whole string to be successful.
  """

  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Option
  # alias Exa.Gis.Location

  # ---------
  # constants
  # ---------

  # the default set of null values
  @nulls ["", "nil", "null", "nan", "inf"]

  # the default set of false values
  @falses ["false", "f"]

  # the default set of true values
  @trues ["true", "t"]

  # -----
  # types
  # -----

  @typedoc """
  A parser function that takes a string,
  and returns a parsed data type.
  If there is no match, return the original string.
  `nil` values are passed through unchanged.
  """
  @type parfun(t) :: (nil | String.t() -> nil | String.t() | t)

  # ----------------
  # public functions
  # ----------------

  @doc """
  Parse a string as `nil`, or the original string.

  All comparisons are case insensitive.
  Lists of matches should be provided in lower case.
  """
  @spec null([String.t()]) :: parfun(nil)
  def null(nulls \\ @nulls) do
    fn s ->
      if String.downcase(s) in nulls, do: nil, else: s
    end
  end

  @doc """
  Parse a string to a boolean.
  `nil` values are passed through unchanged.
  All comparisons are case insensitive.
  Lists of matches should be provided in lower case.

  The default comparisons can be extended and customized,
  for example, to include `0` and `1` when you know 
  it is a boolean not an integer.
  """
  @spec bool([String.t()], [String.t()]) :: parfun(bool())
  def bool(trues \\ @trues, falses \\ @falses) do
    fn
      nil ->
        nil

      str ->
        s = String.downcase(str)

        cond do
          s in trues -> true
          s in falses -> false
          true -> str
        end
    end
  end

  @doc """
  Parse a string to an atom.
  Use this for a small set of categorical (enumerated) variables.

  `nil` values are passed through unchanged.
  The string arguments are preprocessed 
  using the `Exa.String.sanitize!` function.
  The `maxlen` argument is passed through to the sanitize function.

  ***
  This has the possibility to fill up the atom table.
  Only use it for fields that have a small bounded 
  number of possible string values.
  *** 
  """
  @spec atom([String.t()], pos_integer()) :: parfun(bool())
  def atom(values, maxlen \\ 20) do
    fn
      nil ->
        nil

      "" ->
        ""

      str ->
        s = str |> String.downcase() |> Exa.String.sanitize!(maxlen)

        cond do
          s in values -> String.to_atom(s)
          s -> s
        end
    end
  end

  @doc """
  Parse a string as an integer.

  `nil` values are passed through unchanged.
  """
  @spec int() :: parfun(integer())
  def int() do
    fn
      nil ->
        nil

      <<c, _::binary>> = s when is_numstart(c) ->
        case Integer.parse(s) do
          {i, ""} -> i
          _ -> s
        end

      s ->
        s
    end
  end

  @doc """
  Parse a hex string as an integer.
  A leading sign is supported, such as `'-'`.
  `nil` values are passed through unchanged.

  Allow leading `0x`, `#` or `\\u` prefix characters.
  Allow leading `16#` for Erlang hex literals.

  The final result is a single integer value, 
  not a color array (see _Gfx.Color.Col3b_).
  """
  @spec hex() :: parfun(non_neg_integer())
  def hex() do
    fn
      nil ->
        nil

      s ->
        hex =
          case s do
            <<?#, hex::binary>> -> hex
            <<?0, ?x, hex::binary>> -> hex
            <<?\\, ?u, hex::binary>> -> hex
            <<?1, ?6, ?#, hex::binary>> -> hex
            hex -> hex
          end

        case Integer.parse(hex, 16) do
          {i, ""} -> i
          _ -> s
        end
    end
  end

  @doc """
  Parse a string as a float.

  `nil` values are passed through unchanged.
  """
  @spec float() :: parfun(float())
  def float() do
    fn
      nil ->
        nil

      <<c, _::binary>> = s when is_numstart(c) ->
        case Float.parse(s) do
          {x, ""} -> x
          _ -> s
        end

      s ->
        s
    end
  end

  @doc """
  Parse a string as an ISO 8601 Date.

  `nil` values are passed through unchanged.
  """
  @spec date(Calendar.calendar()) :: parfun(Date.t())
  def date(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s ->
        case Date.from_iso8601(s, cal) do
          {:ok, date} -> date
          {:error, _reason} -> s
        end
    end
  end

  @doc "Parse a string as an ISO 8601 Time."
  @spec time(Calendar.calendar()) :: parfun(Time.t())
  def time(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s ->
        case Time.from_iso8601(s, cal) do
          {:ok, time} -> time
          {:error, _reason} -> s
        end
    end
  end

  @doc """
  Parse a string as an ISO 8601 Datetime.

  The string must contain timezone or offset information.
  The result is a UTC `DateTime` together with an offset in seconds.
  """
  @spec datetime(Calendar.calendar() | :extended | :basic) ::
          parfun({DateTime.t(), non_neg_integer()})
  def datetime(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s ->
        case DateTime.from_iso8601(s, cal) do
          {:ok, time, offset} -> {time, offset}
          {:error, _reason} -> s
        end
    end
  end

  @doc """
  Parse a string as an ISO 8601 Naive Datetime.

  If the string contains timezone or offset information, 
  it is ignored, and the result is always a `NaiveDateTime`.
  """
  @spec naive_datetime(Calendar.calendar()) :: parfun(NaiveDateTime.t())
  def naive_datetime(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s ->
        case NaiveDateTime.from_iso8601(s, cal) do
          {:ok, time} -> time
          {:error, _reason} -> s
        end
    end
  end

  @doc """
  Return a composed parser that tries several 
  parsers to find the scalar data type.

  Tries null, bool, int, float, date, time, datetime, naive_datetime
  and the various formats of `Location`.

  Note hex integers are not included, 
  because there is ambiguity with base-10 integers.
  """
  @spec guess([String.t()], [String.t()], [String.t()], Calendar.calendar()) :: parfun(any())
  def guess(nulls \\ @nulls, trues \\ @trues, falses \\ @falses, cal \\ Calendar.ISO) do
    # slow ..... many ways to optimize this ...
    # count delimiters; test numstart and numchars, etc.
    compose([
      null(nulls),
      bool(trues, falses),
      int(),
      float(),
      date(cal),
      time(cal),
      datetime(cal),
      naive_datetime(cal)
      # , &Location.parse/1
    ])
  end

  @doc """
  Generate a parser from a list of parsers. 

  Pass through `nil` and non-strings,
  otherwise try the next parser in the sequence.
  """
  @spec compose([parfun(any())]) :: parfun(any())
  def compose(parsers) when is_list(parsers), do: fn s -> do_par(s, parsers) end

  defp do_par(nil, _), do: nil
  defp do_par(s, [par | parsers]) when is_string(s), do: do_par(par.(s), parsers)
  defp do_par(d, _parsers), do: d

  @doc """
  Return a parser that splits a string into an array of strings.
  The parser does not handle escapes and quotation.
  The string tokens are then optionally trimmed, 
  processed into `nil` values, filtered, 
  and converted to a specific known data type.

  The options are:
  - `:delim` one or more string delimiters (see `String.split()`),
    defaults to comma `","`
  - `:trim` flag to indicate trimming tokens of whitespace
    (note this is _not_ the same meaning as `String.split()`),
    defaults to `true`
  - `:parnull` optional null parser to convert empty string and other values to `nil` 
  - `:filter` flag to filter `nil` tokens after trimming and conversion: 
    remove `nil` (filter `true`); or pass through (filter `false`, default)
  - `:pardata` optional data parser to convert non-`nil` values to a data value
  """
  @spec array(E.options()) :: parfun([any()])
  def array(opts \\ []) do
    delim = Keyword.get(opts, :delim, ",")
    trim? = Option.get_bool(opts, :trim, true)
    parnull = Option.get_fun(opts, :parnull, nil)
    filter? = Option.get_bool(opts, :filter, false)
    pardata = Option.get_fun(opts, :pardata, nil)

    fn
      nil ->
        nil

      s when is_string(s) ->
        s
        |> String.trim()
        |> String.split(delim)
        |> trim(trim?)
        |> par(parnull)
        |> filter(filter?)
        |> par(pardata)
    end
  end

  @spec trim([String.t()], bool()) :: [String.t()]
  defp trim(toks, false), do: toks
  defp trim(toks, true), do: Enum.map(toks, &String.trim/1)

  @spec par([String.t()], nil | fun()) :: [any()]
  defp par(toks, nil), do: toks
  defp par(toks, par), do: Enum.map(toks, fn s -> par.(s) end)

  @spec filter([any()], bool()) :: [any()]
  defp filter(toks, false), do: toks
  defp filter(toks, true), do: Enum.filter(toks, fn s -> not is_nil(s) end)
end

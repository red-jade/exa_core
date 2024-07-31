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
  require Logger

  use Exa.Constants

  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Option

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
  Parse a nullable string.
  The result will be `nil` or the original string.

  All comparisons are case insensitive.

  The default set of null values is:

  `#{@nulls}`.
  """
  @spec p_null([String.t()]) :: parfun(nil)
  def p_null(nulls \\ @nulls) do
    nulls = Enum.map(nulls, &String.downcase/1)

    fn s when is_string(s) ->
      if String.downcase(s) in nulls, do: nil, else: s
    end
  end

  @doc "A no-op parser that passes through a string."
  @spec p_string() :: parfun(String.t())
  def p_string() do
    fn
      nil -> nil
      s when is_string(s) -> s
    end
  end

  @doc """
  A parser that passes through a string 
  if it is valid according to a predicate function.

  There is no type conversion, just a validation.
  """
  @spec p_string(E.predicate?(String.t())) :: parfun(String.t())
  def p_string(valid?) when is_pred(valid?) do
    fn
      nil -> nil
      s when is_string(s) -> if valid?.(s), do: s, else: {:error, s}
    end
  end

  @doc """
  Parse a string to a boolean.
  `nil` values are passed through unchanged.
  All comparisons are case insensitive.

  The default comparisons can be extended and customized,
  for example, to include `0` and `1` when you know 
  it is a boolean not an integer.

  The default set of `true` values is:

  `#{@trues}`.

  The default set of `false` values is:

  `#{@falses}`.
  """
  @spec p_bool([String.t()], [String.t()]) :: parfun(bool())
  def p_bool(trues \\ @trues, falses \\ @falses) do
    trues = Enum.map(trues, &String.downcase/1)
    falses = Enum.map(falses, &String.downcase/1)

    fn
      nil ->
        nil

      str when is_string(str) ->
        s = String.downcase(str)

        cond do
          s in trues -> true
          s in falses -> false
          true -> str
        end
    end
  end

  @doc """
  Parse a string to one of an enumerated list of atoms.
  Use this for a small set of categorical (enumerated) variables.

  Input string arguments are downsized, sanitized 
  and truncated to at most 255 characters.
  See `Exa.String.sanitize!/3` for more details.

  `nil` values are passed through unchanged.

  The empty string returns `nil`.
  """
  @spec p_atom([String.t()]) :: parfun(bool())
  def p_atom(values) do
    {values, maxlen} =
      Enum.reduce(values, {[], 0}, fn v, {vals, maxlen} ->
        {[String.downcase(v) | vals], max(maxlen, String.length(v))}
      end)

    fn
      nil ->
        nil

      "" ->
        nil

      str when is_string(str) ->
        s = str |> String.downcase() |> Exa.String.sanitize!(min(maxlen, 255))

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
  @spec p_int() :: parfun(integer())
  def p_int() do
    fn
      nil ->
        nil

      <<c, _::binary>> = s when is_numstart(c) ->
        case Integer.parse(s) do
          {i, ""} -> i
          _ -> s
        end

      s when is_string(s) ->
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
  @spec p_hex() :: parfun(non_neg_integer())
  def p_hex() do
    fn
      nil ->
        nil

      s when is_string(s) ->
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
  @spec p_float() :: parfun(float())
  def p_float() do
    fn
      nil ->
        nil

      <<c, _::binary>> = s when is_numstart(c) ->
        case Float.parse(s) do
          {x, ""} -> x
          _ -> s
        end

      s when is_string(s) ->
        s
    end
  end

  @doc """
  Parse a string as an ISO 8601 Date.

  `nil` values are passed through unchanged.
  """
  @spec p_date(Calendar.calendar()) :: parfun(Date.t())
  def p_date(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s when is_string(s) ->
        case Date.from_iso8601(s, cal) do
          {:ok, date} -> date
          {:error, _reason} -> s
        end
    end
  end

  @doc "Parse a string as an ISO 8601 Time."
  @spec p_time(Calendar.calendar()) :: parfun(Time.t())
  def p_time(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s when is_string(s) ->
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
  @spec p_datetime(Calendar.calendar() | :extended | :basic) ::
          parfun({DateTime.t(), non_neg_integer()})
  def p_datetime(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s when is_string(s) ->
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
  @spec p_naive_datetime(Calendar.calendar()) :: parfun(NaiveDateTime.t())
  def p_naive_datetime(cal \\ Calendar.ISO) do
    fn
      nil ->
        nil

      s when is_string(s) ->
        case NaiveDateTime.from_iso8601(s, cal) do
          {:ok, time} -> time
          {:error, _reason} -> s
        end
    end
  end

  @doc "Parse a string as a URI."
  @spec p_uri() :: parfun(URI.t())
  def p_uri() do
    fn
      nil ->
        nil

      s when is_string(s) ->
        try do
          URI.parse(s)
        rescue
          err in URI.Error ->
            Logger.error("URI format error: #{inspect(err)}")
            {:error, s}
        end
    end
  end

  @doc "Parse a string and validate as an email."
  @spec p_email() :: parfun(String.t())
  def p_email(), do: p_string(&email_valid?/1)

  @doc """
  Return a composed parser that tries several 
  parsers to find the scalar data type.

  Tries null, bool, int, float, date, time, datetime, naive_datetime.
  Note hex integers are not included, 
  because there is ambiguity with base-10 integers.

  Also see `Exa.Gis.Location.p_guess/4`.
  """
  @spec p_guess([String.t()], [String.t()], [String.t()], Calendar.calendar()) :: parfun(any())
  def p_guess(nulls \\ @nulls, trues \\ @trues, falses \\ @falses, cal \\ Calendar.ISO) do
    # slow ..... many ways to optimize this ...
    # count delimiters; test numstart and numchars, etc.
    compose([
      p_null(nulls),
      p_bool(trues, falses),
      p_int(),
      p_float(),
      p_date(cal),
      p_time(cal),
      p_datetime(cal),
      p_naive_datetime(cal)
    ])
  end

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
  @spec p_array(E.options()) :: parfun([any()])
  def p_array(opts \\ []) do
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

  # TODO - really need tag tuple return types
  # because of pass through string validation (e.g. email)

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

  # -----------------
  # private functions
  # -----------------

  @local_regex ~r<^[[:alnum:]!#$%&'*+-/=?^_`.{|}~]*$>
  @host_regex ~r<^[[:alnum:]]+(-[[:alnum:]]+)*$>
  @tld_regex ~r<^[[:alpha:]]{2,}$>

  @spec email_valid?(String.t()) :: bool()
  defp email_valid?(s) when is_string(s) do
    case String.split(s, "@") do
      segs when length(segs) != 2 ->
        Logger.error("Email must contain exactly one '@' character - '#{s}'")
        false

      [local, domain] ->
        local_valid?(local) and domain_valid?(domain)
    end
  end

  @spec local_valid?(String.t()) :: bool()
  defp local_valid?(local) do
    cond do
      not is_in_range(1, String.length(local), 64) ->
        Logger.error("Email: local part must have 1-64 characters - '#{local}'")
        false

      String.starts_with?(local, ".") ->
        Logger.error("Email: local part starts with '.' - '#{local}'")
        false

      String.ends_with?(local, ".") ->
        Logger.error("Email: local part ends with '.' - '#{local}'")
        false

      String.contains?(local, "..") ->
        Logger.error("Email: local part contains '..' - '#{local}'")
        false

      not Regex.match?(@local_regex, local) ->
        Logger.error("Email: local part contains special characters - '#{local}'")
        false

      true ->
        true
    end
  end

  @spec domain_valid?(String.t()) :: bool()
  defp domain_valid?(domain) do
    doms = domain |> String.split(".") |> Enum.reverse()

    cond do
      not is_in_range(1, String.length(domain), 255) ->
        Logger.error("Email: domain longer than 255 characters - '#{domain}'")
        false

      length(doms) < 2 ->
        Logger.error("Email: domain must have at least 2 segments - '#{domain}'")
        false

      Enum.any?(doms, &(&1 == "")) ->
        Logger.error("Email: domain starts/ends with '.' or contains '..' - '#{domain}'")
        false

      true ->
        [tld | hosts] = doms

        cond do
          not Regex.match?(@tld_regex, tld) ->
            Logger.error("Email: invalid top-level domain - '#{domain}'")
            false

          not Enum.all?(hosts, &Regex.match?(@host_regex, &1)) ->
            Logger.error("Email: invalid domain hostname - '#{domain}'")
            false

          true ->
            true
        end
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

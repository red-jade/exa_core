defmodule Exa.Types do
  @moduledoc "Types and guards for Exa."

  use Exa.Constants

  import Bitwise

  # types ==========

  @typedoc "Optional value type."
  @type maybe(t) :: nil | t

  @typedoc "A predicate to test or filter a value."
  @type predicate?(t) :: (t -> bool())
  defguard is_pred(pred) when is_function(pred, 1)

  @typedoc "Mapper function."
  @type mapper(a, b) :: (a -> b)
  defguard is_mapper(mapr) when is_function(mapr, 1)

  @typedoc "Mapper (zipper) function to zip combine two lists."
  @type bimapper(a, b) :: (a, a -> b)
  defguard is_bimapper(bimapr) when is_function(bimapr, 2)

  @typedoc "Combiner function for reducing over an input enumerable."
  @type reducer(t, acc) :: (t, acc -> acc)
  defguard is_reducer(red) when is_function(red, 2)

  @typedoc "Combiner function for reducing over two input enumerables."
  @type bireducer(t, acc) :: (t, t, acc -> acc)
  defguard is_bireducer(bired) when is_function(bired, 3)

  @typedoc "A reducer with a halting condition."
  @type while_reducer(t, acc) :: (t, acc -> {:cont, acc} | {:halt, acc})
  defguard is_whiler(red) when is_function(red, 2)

  @typedoc "A reducer with a prompt return by throwing `{:return, result}`."
  @type terminator!(t, acc) :: (t, acc -> acc)
  defguard is_terminator(arnie) when is_function(arnie, 2)

  @typedoc "A mapping that is either a map or a mapper function."
  @type mapping(a, b) :: mapper(a, b) | %{a => b}
  defguard is_mapping(mapi) when is_map(mapi) or is_mapper(mapi)

  # atom ----------

  defguard is_nonnil_atom(a) when is_atom(a) and not is_nil(a)

  defguard is_module(m) when is_atom(m)

  # range ----------

  defguard is_range(r) when is_struct(r, Range)

  defguard is_pos_range(r) when is_range(r) and r.first > 0

  defguard is_range(imin, imax) when is_integer(imin) and is_integer(imax) and imin <= imax

  # assume the limits have already been checked: is_range(imin,imax)
  defguard is_in_range(imin, i, imax) when is_integer(i) and imin <= i and i <= imax

  # bit ----------

  @type bit() :: 0 | 1

  defguard is_bit(b) when b === 0 or b === 1

  # byte ----------

  defguard is_byte(b) when is_in_range(0, b, 255)

  # integer ----------

  defguard is_int_nonneg(i) when is_integer(i) and i >= 0

  defguard is_int_pos(i) when is_integer(i) and i > 0

  defguard is_int_even(i) when is_integer(i) and (i &&& 0x01) == 0

  defguard is_int_odd(i) when is_integer(i) and (i &&& 0x01) == 1

  @typedoc "Percent value limited to the range [0,100]."
  @type percent() :: 0..100
  defguard is_pc(i) when is_in_range(0, i, 100)

  # cardinality (count)

  # positive count with a minimum allowed value
  defguard is_count(c, min) when is_integer(c) and c >= min

  @typedoc "Cardinal non-negative count."
  @type count() :: non_neg_integer()
  defguard is_count(c) when is_count(c, 0)

  @typedoc "Positive non-zero count, one or more."
  @type count1() :: pos_integer()
  defguard is_count1(c) when is_count(c, 1)

  @typedoc "Positive count, two or more."
  @type count2() :: pos_integer()
  defguard is_count2(c) when is_count(c, 2)

  # ordinality (index)

  @typedoc "0-based index."
  @type index0() :: non_neg_integer()
  defguard is_index0(i) when is_count(i, 0)

  # test a valid 0-based index into a list
  defguard is_index0(i, ls) when is_list(ls) and is_in_range(0, i, length(ls) - 1)

  @typedoc "1-based index."
  @type index1() :: pos_integer()
  defguard is_index1(i) when is_count(i, 1)

  # size (length) in bytes or characters

  @typedoc "Byte or bit size."
  @type bsize() :: non_neg_integer()
  defguard is_bsize(sz) when is_count(sz, 0)

  @typedoc "Character size."
  @type csize() :: non_neg_integer()
  defguard is_csize(sz) when is_count(sz, 0)

  @typedoc "Integer extended with +- infinity."
  @type inf_int() :: integer() | :neg_inf | :pos_inf

  @typedoc "Float extended with +- infinity."
  @type inf_float() :: float() | :neg_inf | :pos_inf

  @typedoc "Number extended with +- infinity."
  @type inf_number() :: number() | :neg_inf | :pos_inf

  # time ----------

  @typedoc "A non-zero finite timeout (ms)."
  @type timeout1() :: pos_integer()
  defguard is_timeout1(t) when is_int_pos(t)

  @typedoc """
  Microsecond clock time.

  The value taken from `:erlang.monotonic_time`.
  Note that since Erlang OTP 26,
  this value can be negative.

  Never use the raw value, only use comparisons 
  with later calls to monotonic time.
  """
  @type time_micros() :: integer()

  @typedoc "Microsecond elapsed duration."
  @type duration_micros() :: non_neg_integer()

  @typedoc "Conventional millisecond times and durations (sleep, after, etc.)."
  @type duration_millis() :: non_neg_integer()

  # float ----------

  # test for +-0.0
  # also see Exa.math.zero?
  defguard is_zero(f) when f == +0.0 or f == -0.0

  # positive floats (no tolerance)
  # also see Exa.Math.pos?
  @type pos_float() :: float()
  defguard is_float_pos(f) when is_float(f) and f > 0.0

  # non-negative floats (no tolerance)
  # also see Exa.Math.nonneg?
  @type nonneg_float() :: float()
  defguard is_float_nonneg(f) when is_float(f) and f >= 0.0

  @typedoc "A floating point tolerance."
  @type epsilon() :: pos_float()
  defguard is_eps(e) when is_float_pos(e)

  @typedoc "A normalized float value in the range (0.0,1.0) inclusive."
  @type unit() :: float()
  defguard is_unit(f) when is_float(f) and 0.0 <= f and f <= 1.0

  @typedoc "A normalized float value in the range (-1.0,1.0) inclusive."
  @type unit_sym() :: float()
  defguard is_unit_sym(f) when is_float(f) and -1.0 <= f and f <= 1.0

  # test for finite float range
  defguard is_rangef(p, q) when is_float(p) and is_float(q) and p < q

  # test if a float has exactly an integer value
  # also see Exa.Math.int?
  defguard is_intf(x) when ceil(x) == floor(x)

  # angular measures
  @type degrees() :: float()
  @type radians() :: float()

  @typedoc """
  A parameter for a parametric definition.
  The primitive could be ray, curve, patch or texture. 

  The values 0.0,1.0 may be significant,
  but the type is not restricted to the unit range. 
  The parametrization may extend outside the unit range.
  For a constrained type, see `unit`.
  """
  @type param() :: float()
  defguard is_param(t) when is_float(t)

  @typedoc "Comparison of two floating-point numbers."
  @type compare() :: :below | :equal | :above
  defguard is_compare(b) when b in [:below, :equal, :above]

  @typedoc "Comparison of a floating-point value to a range."
  @type between() ::
          :below_min
          | :equal_min
          | :between
          | :equal_max
          | :above_max
  defguard is_between(b)
           when b in [
                  :below_min,
                  :equal_min,
                  :between,
                  :equal_max,
                  :above_max
                ]

  # binary ----------

  @typedoc "Type alias for bitstring."
  @type bits() :: bitstring()

  # char ----------

  # includes null 0x0 and control characters
  defguard is_char(c) when is_in_range(0x000000, c, 0x10FFFF)

  # ASCII character classes

  defguard is_digit(c) when ?0 <= c and c <= ?9
  defguard is_numstart(c) when is_digit(c) or c in [?-, ?+]
  defguard is_numchar(c) when is_numstart(c) or c in [?., ?E, ?e]
  defguard is_hexchar(c) when is_digit(c) or c in ~c"abcdefABCDEF"
  defguard is_upper(c) when ?A <= c and c <= ?Z
  defguard is_lower(c) when ?a <= c and c <= ?z
  defguard is_alpha(c) when is_lower(c) or is_upper(c)
  defguard is_alphanum(c) when is_alpha(c) or is_digit(c)
  defguard is_namestart(c) when is_alpha(c) or c == ?_
  defguard is_namechar(c) when is_namestart(c) or is_digit(c)
  defguard is_eol(c) when c in @ascii_eol
  defguard is_ws(c) when c in @ascii_ws
  defguard is_filechar(c) when is_alphanum(c) or c in @safe_file

  # printable ascii: (0x20) ' ', '!', ... '}', '~' (0x7E)
  defguard is_ascii(c) when is_integer(c) and (0x20 <= c and c <= 0x7E)

  # Unicode character classes

  defguard is_uni_eol(c) when is_eol(c) or c in [0x85, 0x2028, 0x2029]

  defguard is_uni_ws(c)
           when is_ws(c) or is_uni_eol(c) or
                  (c >= 0x2000 and c <= 0x200A) or c in [0xA0, 0x202F, 0x205F, 0x3000]

  @typedoc "An encoding indicated by a Byte Order Mark (BOM)."
  @type bom_encoding() :: :no_bom | :utf8 | :utf16be | :utf16le | :utf32be | :utf32le

  # string ----------

  defguard is_string(str) when is_binary(str)

  defguard is_string_nonempty(nes) when is_string(nes) and nes != ""

  # only works for ASCII
  defguard is_string_fix(s, n) when is_string(s) and byte_size(s) == n

  @typedoc """
  An identifier name, roughly equivalent to programming language names.
  A non-empty string with first character `is_namestart` and all 
  subsequent characters are `is_namechar`.

  These names are a subset of XML NCName (used for node IDs in XML).
  An NCName may also contain `'-'` and `'.'`.
  """
  @type name() :: String.t()
  defguard is_name(s) when is_string_nonempty(s)

  @doc "Test if a value is a name."
  @spec name?(any()) :: bool()
  def name?(s) when is_name(s) do
    [c | cs] = String.to_charlist(s)
    is_namestart(c) and Enum.all?(cs, &is_namechar/1)
  end

  # list ----------

  defguard is_list_nonempty(nel) when is_list(nel) and nel != []

  defguard is_list_fix(fl, n) when is_int_nonneg(n) and is_list(fl) and length(fl) == n

  # keyword ----------

  defguard is_kv(kv) when is_tuple(kv) and tuple_size(kv) == 2 and is_atom(elem(kv, 0))

  # dialyzer does not like hd() on potentially empty list
  defguard is_keyword(k) when is_list(k) and (k == [] or is_kv(hd(k)))

  @type options() :: Keyword.t()
  defguard is_options(o) when is_keyword(o)

  # tuple ----------

  defguard is_tuple_nonempty(tup) when is_tuple(tup) and tup != {}

  defguard is_tuple_fix(tup, n) when is_int_nonneg(n) and is_tuple(tup) and tuple_size(tup) == n

  defguard is_tuple_tag(tup, tag) when is_tuple(tup) and elem(tup, 0) == tag

  defguard is_tuple_tag(tup, n, tag) when is_tuple_fix(tup, n) and elem(tup, 0) == tag

  # map ----------

  defguard is_map_empty(map) when is_map(map) and map_size(map) == 0

  defguard is_map_nonempty(map) when is_map(map) and map_size(map) > 0

  # set ----------

  defguard is_set(s) when is_struct(s, MapSet)

  # warning: break encapsulation of opaque MapSet type
  #          cannot disable dialyzer warning for guards

  defguard set_size(s) when is_set(s) and map_size(s.map)

  defguard is_set_empty(s) when is_set(s) and set_size(s) == 0

  defguard is_set_nonempty(s) when is_set(s) and set_size(s) != 0

  defguard is_set_member(s, x) when is_set(s) and is_map_key(s.map, x)

  # URI ----------

  defguard is_uri(uri) when is_struct(uri, URI)

  # results ----------

  @typedoc "Standard discriminated return."
  @type result(t) :: {:ok, t} | {:error, any()}

  defguard is_ok(ok) when is_tuple_tag(ok, 2, :ok)
  defguard is_err(err) when is_tuple_tag(err, 2, :error)
  defguard is_result(res) when is_tuple_fix(res, 2) and elem(res, 0) in [:ok, :error]

  @typedoc """
  Standard return with timeout.

  Single functions may return `{:timeout, nil}`,
  but map or reduce may return a partial result
  (truncated list or partial accumulator).
  """
  @type tresult(t) :: result(t) | {:timeout, nil | t}

  defguard is_tresult(res) when is_tuple_fix(res, 2) and elem(res, 0) in [:ok, :error, :timeout]

  # Processes and messages ----------

  # trivial alias to make it smaller
  defguard is_ref(ref) when is_reference(ref)

  @typedoc "A standard message format, with payload type parameter."
  @type message(t) :: {pid(), reference(), t}

  defguard is_message(m) when is_tuple_fix(m, 3) and is_pid(elem(m, 0)) and is_ref(elem(m, 1))

  @typedoc """
  A unique message identifier.
  Contains a source PID and a unique Reference.
  """
  @type pidref() :: {pid(), reference()}

  defguard is_pidref(m) when is_tuple_fix(m, 2) and is_pid(elem(m, 0)) and is_ref(elem(m, 1))

  @typedoc """
  A match for processing messages.

  The PID and Reference will label 0th and/or 1st elements of the message.

  If the match or the message do not conform to the standard message pattern,
  then assume a generic constant message (not included).
  """
  @type match() :: pid() | reference() | pidref()

  defguardp is_match_pid(pid, msg) when is_pid(pid) and elem(msg, 0) == pid
  defguardp is_match_ref(ref, msg) when is_ref(ref) and elem(msg, 1) == ref

  defguard is_match_prf(prf, msg)
           when is_pidref(prf) and elem(msg, 0) == elem(prf, 0) and elem(msg, 1) == elem(prf, 1)

  defguard is_match(mat, msg)
           when is_message(msg) and
                  (is_match_prf(mat, msg) or
                     is_match_pid(mat, msg) or
                     is_match_ref(mat, msg))

  # files ----------

  @typedoc """
  Tag a string as a filename.
  The value should be the output of `Path.to_string`.
  """
  @type filename() :: String.t()
  defguard is_filename(f) when is_string_nonempty(f)

  @typedoc """
  Tag a string or atom as a filetype.
  The value should be lowercase alphanumeric ASCII.
  """
  @type filetype() :: atom() | String.t()
  defguard is_filetype(ft) when is_string_nonempty(ft) or is_atom(ft)

  # types of specific length ----------

  @type uint() :: non_neg_integer()
  defguard is_uint(i) when is_int_nonneg(i)

  @type uint4() :: 0..15
  defguard is_uint4(i) when is_integer(i) and @min_uint <= i and i <= @max_uint4

  @type uint8() :: 0..255
  defguard is_uint8(i) when is_integer(i) and @min_uint <= i and i <= @max_uint8

  @type uint12() :: non_neg_integer()
  defguard is_uint12(i) when is_integer(i) and @min_uint <= i and i <= @max_uint12

  @type uint16() :: non_neg_integer()
  defguard is_uint16(i) when is_integer(i) and @min_uint <= i and i <= @max_uint16

  @type uint32() :: non_neg_integer()
  defguard is_uint32(i) when is_integer(i) and @min_uint <= i and i <= @max_uint32

  @type uint64() :: non_neg_integer()
  defguard is_uint64(i) when is_integer(i) and @min_uint <= i and i <= @max_uint64

  @type int8() :: integer()
  defguard is_int8(i) when is_integer(i) and @min_int8 <= i and i <= @max_int8

  @type int12() :: integer()
  defguard is_int12(i) when is_integer(i) and @min_int12 <= i and i <= @max_int12

  @type int16() :: integer()
  defguard is_int16(i) when is_integer(i) and @min_int16 <= i and i <= @max_int16

  @type int32() :: integer()
  defguard is_int32(i) when is_integer(i) and @min_int32 <= i and i <= @max_int32

  @type int64() :: integer()
  defguard is_int64(i) when is_integer(i) and @min_int64 <= i and i <= @max_int64

  @type f32() :: float()
  defguard is_f32(x) when is_float(x) and @min_f32 <= x and x <= @max_f32

  @type f64() :: float()
  defguard is_f64(x) when is_float(x) and @min_f64 <= x and x <= @max_f64
end

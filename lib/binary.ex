defmodule Exa.Binary do
  @moduledoc "Utilities for binary and bitstring buffers."

  import Bitwise

  import Exa.Types
  alias Exa.Types, as: E

  # -----
  # types 
  # -----

  @typedoc """
  Binary part specifications.
  The part has a source binary, start address (0-based position)
  and the number of bytes.

  For more information, 
  see `Kernel.binary_part/3` function 
  and `:erlang.binary` module.
  """
  @type part() :: {binary(), pos :: E.index0(), len :: E.count()}
  @type parts() :: [part()]

  # ----------------------
  # calculate bits & bytes
  # ----------------------

  @doc "Bitwise `div(i,8)`."
  defguard div8(i) when i >>> 3

  @doc "Bitwise `rem(i,8)`."
  defguard rem8(i) when i &&& 0x07

  @doc "The maximum value of an unsigned int with a given number of bits."
  defguard max_uint(nbit) when (1 <<< nbit) - 1

  @doc "The maximum value of a signed int with a given number of bits."
  defguard max_int(nbit) when (1 <<< (nbit - 1)) - 1

  @doc "The minimum value of a signed int with a given number of bits."
  defguard min_int(nbit) when -(1 <<< (nbit - 1))

  @doc """
  The number of significant bits in a non-negative integer.
  Same as the number of bits required to represent the value in an unsigned integer.
  Equivalent to `1 + floor(:math.log2(i))` for i > 0, and `nbits(0) = 0`.
  """
  @spec nbits(non_neg_integer()) :: non_neg_integer()
  def nbits(i) when is_int_nonneg(i), do: ubitz(i, 0)

  @spec ubitz(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp ubitz(0, n), do: n
  defp ubitz(i, n), do: ubitz(i >>> 1, n + 1)

  @doc "The number of bits required to represent the value in a signed integer."
  @spec signed_bits(integer()) :: non_neg_integer()
  def signed_bits(i) when is_integer(i), do: sbitz(i)

  @spec sbitz(integer()) :: non_neg_integer()
  defp sbitz(0), do: 0
  defp sbitz(i) when is_int_pos(i), do: nbits(i) + 1
  defp sbitz(i) when is_integer(i), do: nbits(-i - 1) + 1

  @doc """
  Get the mid-point of an integer range.

  Round up when the number of values is even,
  to give more values below the mid-point 
  (like 2s-complement signed integer ranges).

  Equaivalent to `trunc(ceil((imax+imin)/2)))`.
  """
  def imid(imin, imax) when is_range(imin, imax) do
    imin + ((imax - imin + 1) >>> 0x01)
  end

  @doc """
  Get the number of whole bytes required for a number of bits.

  The result is the total bytes, not the extra bits of padding.
  The result for 0 bits is 0.
  """
  @spec padded_bits(E.bsize()) :: E.bsize()
  def padded_bits(nbits) when (nbits &&& 0x07) == 0, do: div8(nbits)
  def padded_bits(nbits), do: 1 + div8(nbits)

  @doc """
  Get the number of bits required to pad to the next byte boundary.

  The result is only the extra bits required, 
  not the total number of padded bits.
  The result for any multiple of 8 is 0 bits.
  """
  @spec pad_bits(E.bsize()) :: E.bsize()
  def pad_bits(nbits) when (nbits &&& 0x07) == 0, do: 0
  def pad_bits(nbits), do: 8 - rem8(nbits)

  @doc """
  Get the additional byte padding to the next n-byte boundary.

  The result is the extra number of pad bytes, 
  not the total including the original bytes.
  """
  @spec pad_bytes(E.bsize(), pos_integer()) :: E.bsize()
  def pad_bytes(_nbyt, 1), do: 0
  def pad_bytes(nbyte, 2), do: nbyte &&& 0x01
  def pad_bytes(nbyte, 4), do: do_pad(4, nbyte &&& 0x03)
  def pad_bytes(nbyte, 8), do: do_pad(8, nbyte &&& 0x07)
  def pad_bytes(nbyte, k), do: do_pad(k, nbyte &&& k - 1)

  defp do_pad(_, 0), do: 0
  defp do_pad(k, r), do: k - r

  @doc """
  Get the padded number of bytes to the next boundary.
  The result is the total including the original bytes,
  not just the extra number of pad bytes. 
  """
  @spec padded_bytes(E.bsize(), pos_integer()) :: E.bsize()
  def padded_bytes(nbytes, boundary), do: nbytes + pad_bytes(nbytes, boundary)

  @doc """
  Get the number of bytes required to divide a buffer size _n_ 
  into _k_ equal, or approximately equal, parts.

  If the total size _n_ is an exact multiple of _k,_
  the result is simply integer _n/k_ which is the size of the equal chunks. 
  Otherwise, the number of chunks is _m,_ 
  for _m-1_ equal parts with the chunk size, 
  plus one smaller remainder chunk.
  """
  @spec chunk_size(n :: E.bsize(), k :: E.bsize()) :: E.bsize()
  def chunk_size(n, 2) when (n &&& 0x01) == 0, do: n >>> 1
  def chunk_size(n, 4) when (n &&& 0x03) == 0, do: n >>> 2
  def chunk_size(n, 8) when (n &&& 0x07) == 0, do: n >>> 3
  def chunk_size(n, 16) when (n &&& 0x0F) == 0, do: n >>> 4
  def chunk_size(n, k) when rem(n, k) == 0, do: div(n, k)
  def chunk_size(n, k), do: 1 + div(n, k)

  # -----------------------------------
  # bit version of the colorb behaviour
  # -----------------------------------

  @doc """
  Read the first bit from a buffer.
  Return the bit and the remaining buffer.
  """
  @spec from_bit(E.bits()) :: {E.bit(), E.bits()}
  def from_bit(<<b::1, rest::binary>>), do: {b, rest}

  @doc "Append a bit to a buffer."
  @spec append_bit(E.bits(), E.bit()) :: E.bits()
  def append_bit(buf, b), do: <<buf::binary, b::1>>

  @doc "Convert an integer bit to a single-bit buffer."
  @spec to_bit(E.bit()) :: E.bits()
  def to_bit(b), do: <<b::1>>

  # -----------------------------------
  # conversions and access bits & bytes
  # -----------------------------------

  @doc "Convert all of a bitstring to a list of integer bits."
  @spec to_bits(E.bits()) :: [E.bit()]
  def to_bits(bits), do: bits |> do_tbits([]) |> Enum.reverse()

  # note no reverse here, so bits are in reverse order
  @spec do_tbits(E.bits(), [E.bit()]) :: [E.bit()]
  defp do_tbits(<<b::1, rest::bits>>, bits), do: do_tbits(rest, [b | bits])
  defp do_tbits(<<>>, bits), do: bits

  @doc "Create a new bitstring from a list of integer bits."
  @spec from_bits([E.bit()]) :: E.bits()
  def from_bits(bits) when is_list(bits), do: do_fbits(bits, <<>>)

  @spec do_fbits([E.bits()], E.bits()) :: E.bits()
  defp do_fbits([b | bits], out), do: do_fbits(bits, <<out::bits, b::1>>)
  defp do_fbits([], out), do: out

  @doc "Convert a bitstring to a string of binary digits."
  @spec to_bitstr(E.bits()) :: String.t()
  def to_bitstr(bits) when is_bits(bits), do: do_b2s(bits, <<>>)

  defp do_b2s(<<b::1, rest::bits>>, str), do: do_b2s(rest, <<str::binary, (?0+b)::8>>)
  defp do_b2s(<<>>, str), do: str

  @doc "Convert a string of binary digits to a bitstring."
  @spec from_bitstr(String.t()) :: E.bits()
  def from_bitstr(str) when is_string(str), do: do_s2b(str, <<>>)

  defp do_s2b(<<?0::8, rest::binary>>, bits), do: do_s2b(rest, <<bits::bits, 0::1>>)
  defp do_s2b(<<?1::8, rest::binary>>, bits), do: do_s2b(rest, <<bits::bits, 1::1>>)
  defp do_s2b(<<>>, str), do: str

  @doc "Convert a non-negative integer to a bitstring."
  def from_uint(i) when is_int_nonneg(i), do: from_uint(i, nbits(i))

  @doc "Convert a non-negative integer to a fixed width bitstring."
  def from_uint(i, n) when is_int_nonneg(i) and is_count(n) and i < (1 <<< n) do
    do_i2b(i, n, <<>>)
  end

  defp do_i2b(_i, 0, bits), do: bits

  defp do_i2b(i, n, bits) do
    n_1 = n - 1
    mask = i &&& ((1 <<< n_1) - 1)
    shift = (i >>> n_1) &&& 0x01
    do_i2b(mask, n_1, <<bits::bits, shift::1>>)
  end

  @doc """
  Take some of a bitstring as a list of integer bits.

  Copy the first n bits to the output.

  If n is -ve, it is interpreted as pad distance 
  to count back from the end of the bits.

  If n exceeds the length of the bits,
  the whole bits is used.
  """
  @spec take_bits(E.bits(), integer()) :: [E.bit()]
  def take_bits(_bits, 0), do: []
  def take_bits(bits, pad) when pad < 0, do: do_bits(bits, bit_size(bits) + pad, [])
  def take_bits(bits, n) when n > 0, do: do_bits(bits, min(n, bit_size(bits)), [])

  @spec do_bits(E.bits(), E.count(), [E.bit()]) :: [E.bit()]
  defp do_bits(_, 0, bits), do: Enum.reverse(bits)
  defp do_bits(<<b::1, rest::bits>>, n, bits), do: do_bits(rest, n - 1, [b | bits])

  @doc "Convert all of a binary to a list of integer bytes."
  @spec to_bytes(binary()) :: [byte()]
  def to_bytes(bin), do: :binary.bin_to_list(bin)

  @doc "Build a binary from a list of integer bytes."
  @spec from_bytes([byte()]) :: binary()
  def from_bytes(bytes), do: :binary.list_to_bin(bytes)

  @doc "Get the nth byte from a buffer as an unsigned integer value 0..255."
  @spec byte(binary(), E.count()) :: byte()
  def byte(buf, nbyte), do: :binary.at(buf, nbyte)

  @doc """
  Get the _{nbyte, nbit}_ bit from a buffer.

  The `nbyte` is 0-based index from the start of the buffer.
  The `nbit` is 0-based index in order from left to right,
  so most-significant bit first (0), least significant last (7).

  nbyte = 0..(byte_size(buf)-1) 

  nbit = 0..7
  """
  @spec bit(E.bits(), {non_neg_integer(), 0..7}) :: E.bit()
  def bit(buf, {nbyte, nbit}), do: byte(buf, nbyte) >>> (7 - nbit) &&& 0x01

  @doc """
  Set the _{nbyte, nbit}_ bit in a buffer.

  The `nbyte` is 0-based index from the start of the buffer.
  The `nbit` is 0-based index in order from left to right,
  so most-significant bit first (0), least significant last (7).
  """
  @spec set_bit(E.bits(), {non_neg_integer(), 0..7}, E.bit()) :: E.bits()
  def set_bit(buf, {nbyte, nbit}, b)
      when is_bit(b) and
             is_in_range(0, (nbyte <<< 3) + nbit, (byte_size(buf) <<< 3) - 1) do
    sz = (nbyte <<< 3) + nbit
    <<pre::size(sz)-bits, _::1, post::bits>> = buf
    <<pre::bits, b::1, post::bits>>
  end

  @doc """
  Count the number of set bits (1s) in a 
  bitstring, binary or unsigned integer.
  """
  @spec nset(E.bits() | non_neg_integer()) :: E.count()
  def nset(i) when is_int_nonneg(i), do: nset_int(i, 0)
  def nset(buf) when is_bits(buf), do: nset_bit(buf, 0)

  @spec nset_int(non_neg_integer(), E.count()) :: E.count()
  defp nset_int(0, n), do: n
  defp nset_int(i, n), do: nset_int(i >>> 8, n + nset_byte(i &&& 0xFF))

  @spec nset_bit(E.bits(), E.count()) :: E.count()
  # assumes unrolled shift-n-mask is faster than 
  # recursive reduction over pattern matched bits
  defp nset_bit(<<b::8, rest::bits>>, n), do: nset_bit(rest, n + nset_byte(b))
  defp nset_bit(<<0::1, rest::bits>>, n), do: nset_bit(rest, n)
  defp nset_bit(<<1::1, rest::bits>>, n), do: nset_bit(rest, n + 1)
  defp nset_bit(<<>>, n), do: n

  @spec nset_byte(E.byte()) :: 0..8
  defp nset_byte(i) do
    (i &&& 0x1) +
      (i >>> 1 &&& 0x01) +
      (i >>> 2 &&& 0x01) +
      (i >>> 3 &&& 0x01) +
      (i >>> 4 &&& 0x01) +
      (i >>> 5 &&& 0x01) +
      (i >>> 6 &&& 0x01) +
      (i >>> 7 &&& 0x01)
  end

  @doc """
  Reverse a binary as bytes.

  Equivalent to `buf |> to_bytes() |> Enum.reverse() |> from_bytes()`.
  """
  @spec reverse_bytes(binary()) :: binary()
  def reverse_bytes(buf) when is_binary(buf) do
    # is there a size limit for this hack?
    sz = bit_size(buf)
    <<x::size(sz)-integer-little>> = buf
    <<x::size(sz)-integer-big>>
  rescue
    _ -> buf |> to_bytes() |> Enum.reverse() |> from_bytes()
  end

  @doc "Reverse a bitstring as bits."
  @spec reverse_bits(E.bits()) :: E.bits()
  def reverse_bits(buf), do: buf |> do_tbits([]) |> from_bits()

  # ---------------
  # split and merge
  # ---------------

  @doc """
  Split a binary buffer into chunks,
  where the chunk is an integral multiple of a unit size (row size).

  If the buffer is smaller than the unit size or chunk size,
  then the whole buffer is returned in a singleton list.

  Otherwise, each chunk will be a multiple of the (row) unit size. 
  The number of units in each chunk will be the largest multiple 
  of the unit size that does not exceed the target chunk size.

  If the buffer is not an integral multiple of the chunk size,
  there will be a final smaller chunk containing the remainder of the buffer.

  For example, consider a 32x32 image. The row size is 32. 
  A request to split the image into chunks of 100 bytes, 
  willl use an actual chunk size of 3x32=96.
  There will be 10 chunks of 3 rows (96 bytes)
  and one remainder chunk of 2 rows (64 bytes).
  """
  @spec split(binary(), E.bsize(), E.bsize()) :: [binary()]
  def split(buf, unit_size, chunk_size) when rem(byte_size(buf), unit_size) == 0 do
    buf_size = byte_size(buf)
    chunk_size = max(chunk_size, unit_size)

    if buf_size <= chunk_size do
      [buf]
    else
      chunk = unit_size * div(chunk_size, unit_size)
      nchunk = div(buf_size, chunk)

      {addr, parts} =
        Enum.reduce(1..nchunk, {0, []}, fn _, {addr, parts} ->
          {addr + chunk, [{buf, addr, chunk} | parts]}
        end)

      parts =
        case rem(buf_size, chunk) do
          0 -> parts
          rem -> [{buf, addr, rem} | parts]
        end

      parts |> Enum.reverse() |> parts()
    end
  end

  @doc """
  Assemble parts from an edit list.
  Equivalent to `parts()` and `concat()` in a single pass.
  Edits can contain overlapping segments or different image sources.
  """
  @spec merge(parts()) :: binary()
  def merge(parts) do
    Enum.reduce(parts, <<>>, fn {bin, k, n}, buf ->
      <<buf::binary, binary_part(bin, k, n)::binary>>
    end)
  end

  @doc """
  Combine binaries into a single buffer.
  Equivalent to `IO.iodata_to_binary`.
  """
  @spec concat([binary()]) :: binary()
  def concat(bins), do: Enum.reduce(bins, fn bin, buf -> <<buf::binary, bin::binary>> end)

  @doc "Build a list of binary buffers from an edit list."
  @spec parts(parts()) :: [binary()]
  def parts(parts), do: Enum.map(parts, fn {bin, k, n} -> binary_part(bin, k, n) end)

  @doc """
  Take a number of bytes from a non-empty buffer.

  Return the prefix bytes and the remainder of the buffer.
  """
  @spec take(binary(), E.count()) :: {binary(), binary()}

  def take(<<>>, _), do: raise(ArgumentError, message: "Empty buffer")
  def take(<<rest::binary>>, 0), do: {<<>>, rest}
  def take(<<a, rest::binary>>, 1), do: {<<a>>, rest}
  def take(<<a, b, rest::binary>>, 2), do: {<<a, b>>, rest}
  def take(<<a, b, c, rest::binary>>, 3), do: {<<a, b, c>>, rest}
  def take(<<a, b, c, d, rest::binary>>, 4), do: {<<a, b, c, d>>, rest}

  def take(buf, n) when n > 4 do
    {binary_part(buf, 0, n), binary_part(buf, n, byte_size(buf) - n)}
  end

  # ---------------
  # read data types
  # ---------------

  # TODO - should add native here, and make it default?
  @type endianness() :: :little | :big

  @doc "Convert a UTF16 buffer to a (UTF8) binary String."
  def utf16(binary, endian \\ :big) do
    :unicode.characters_to_binary(binary, {:utf16, endian})
  end

  @doc "Convert a UTF32 buffer to a (UTF8) binary String."
  def utf32(binary, endian \\ :big) do
    :unicode.characters_to_binary(binary, {:utf32, endian})
  end

  # read floats --------

  @doc "Get a 64-bit float from a buffer."
  @spec float64(E.bits(), endianness()) :: {E.f64(), E.bits()}
  def float64(buf, endian \\ :big), do: float(buf, 64, endian)

  @doc "Get a 32-bit float from a buffer."
  @spec float32(E.bits(), endianness()) :: {E.f32(), E.bits()}
  def float32(buf, endian \\ :big), do: float(buf, 32, endian)

  @doc "Get a 16-bit float from a buffer."
  @spec float16(E.bits(), endianness()) :: {E.f32(), E.bits()}
  def float16(buf, endian \\ :big), do: float(buf, 32, endian)

  @doc "Get a float of specified bit size from a buffer."
  @spec float(E.bits(), E.bsize(), endianness()) :: {float(), E.bits()}

  def float(buf, sz, :big) do
    <<f::size(sz)-float-big, rest::binary>> = buf
    {f, rest}
  end

  def float(buf, sz, :little) do
    <<f::size(sz)-float-little, rest::binary>> = buf
    {f, rest}
  end

  # read integers --------

  @doc "Get an unsigned 64-bit integer from a buffer."
  @spec uint64(E.bits(), endianness()) :: {E.uint64(), E.bits()}
  def uint64(buf, endian \\ :big), do: uint(buf, 64, endian)

  @doc "Get a signed 64-bit integer from a buffer."
  @spec int64(E.bits(), endianness()) :: {E.int64(), E.bits()}
  def int64(buf, endian \\ :big), do: int(buf, 64, endian)

  @doc "Get an unsigned 32-bit integer from a buffer."
  @spec uint32(E.bits(), endianness()) :: {E.uint32(), E.bits()}
  def uint32(buf, endian \\ :big), do: uint(buf, 32, endian)

  @doc "Get a signed 32-bit integer from a buffer."
  @spec int32(E.bits(), endianness()) :: {E.int32(), E.bits()}
  def int32(buf, endian \\ :big), do: int(buf, 32, endian)

  @doc "Get an unsigned 16-bit integer from a buffer."
  @spec uint16(E.bits(), endianness()) :: {E.uint16(), E.bits()}
  def uint16(buf, endian \\ :big), do: uint(buf, 16, endian)

  @doc "Get a signed 16-bit integer from a buffer."
  @spec int16(E.bits(), endianness()) :: {E.int16(), E.bits()}
  def int16(buf, endian \\ :big), do: int(buf, 16, endian)

  @doc "Get an unsigned 8-bit integer from a buffer."
  @spec uint8(E.bits(), endianness()) :: {E.uint8(), E.bits()}
  def uint8(buf, endian \\ :big), do: uint(buf, 8, endian)

  @doc "Get a signed 8-bit integer from a buffer."
  @spec int8(E.bits(), endianness()) :: {E.uint8(), E.bits()}
  def int8(buf, endian \\ :big), do: int(buf, 8, endian)

  @doc "Get an unsigned integer with a specified bit size from a buffer."
  @spec uint(E.bits(), E.bsize(), endianness()) :: {E.uint(), E.bits()}
  def uint(buf, sz, endian \\ :big)

  def uint(buf, sz, :big) do
    <<i::size(sz)-integer-unsigned-big, rest::bits>> = buf
    {i, rest}
  end

  def uint(buf, sz, :little) do
    <<i::size(sz)-integer-unsigned-little, rest::bits>> = buf
    {i, rest}
  end

  @doc "Get an unsigned integer of arbitrary size from the whole buffer."
  @spec to_uint(E.bits(), endianness()) :: E.uint()
  def to_uint(buf, endian \\ :big)

  def to_uint(buf, :big) do
    <<i::size(bit_size(buf))-integer-unsigned-big>> = buf
    i
  end

  def to_uint(buf, :little) do
    <<i::size(bit_size(buf))-integer-unsigned-little>> = buf
    i
  end

  @doc "Get a signed integer with a specified bit size from a buffer."
  @spec int(E.bits(), E.bsize(), endianness()) :: {E.uint(), E.bits()}
  def int(buf, sz, endian \\ :big)

  def int(buf, sz, :big) do
    <<i::size(sz)-integer-signed-big, rest::bits>> = buf
    {i, rest}
  end

  def int(buf, sz, :little) do
    <<i::size(sz)-integer-signed-little, rest::bits>> = buf
    {i, rest}
  end

  # read fixed point --------

  @doc "Read 32-bit 16.16 signed fixed point value from a buffer."
  @spec fixed_16_16(E.bits(), endianness()) :: {float(), E.bits()}
  def fixed_16_16(buf, endian \\ :big) do
    {i, rest} = int32(buf, endian)
    {i / (1 <<< 16), rest}
  end

  @doc "Read 16-bit 2.14 signed fixed point value from a buffer."
  @spec fixed_2_14(E.bits(), endianness()) :: {float(), E.bits()}
  def fixed_2_14(buf, endian \\ :big) do
    {i, rest} = int16(buf, endian)
    {i / (1 <<< 14), rest}
  end

  # TODO - shortFrac is an int16_t with a bias of 14. 
  #        numbers between 1.999 (0x7fff) and -2.0 (0x8000). 
  #         1.0 is stored as  16384 (0x4000) 
  #        -1.0 is stored as -16384 (0xc000)
  # how is this different from fixed_2_14 ?

  # write integers ----------

  @doc "Append an unsigned 64-bit integer to a buffer."
  @spec append_uint64(E.bits(), non_neg_integer(), endianness()) :: E.bits()
  def append_uint64(buf, i, endian \\ :big), do: append_uint(buf, i, 64, endian)

  @doc "Append an unsigned 32-bit integer to a buffer."
  @spec append_uint32(E.bits(), non_neg_integer(), endianness()) :: E.bits()
  def append_uint32(buf, i, endian \\ :big), do: append_uint(buf, i, 32, endian)

  @doc "Append an unsigned 16-bit integer to a buffer."
  @spec append_uint16(E.bits(), non_neg_integer(), endianness()) :: E.bits()
  def append_uint16(buf, i, endian \\ :big), do: append_uint(buf, i, 16, endian)

  @doc "Append an unsigned 8-bit integer to a buffer."
  @spec append_uint8(E.bits(), non_neg_integer(), endianness()) :: E.bits()
  def append_uint8(buf, i, endian \\ :big), do: append_uint(buf, i, 8, endian)

  @doc "Append an unsigned integer of specified bit size to a buffer."
  @spec append_uint(E.bits(), non_neg_integer(), E.bsize(), endianness()) :: E.bits()
  def append_uint(buf, i, sz, endian \\ :big)
  def append_uint(buf, i, sz, :big), do: <<buf::bits, i::size(sz)-integer-signed-big>>
  def append_uint(buf, i, sz, :little), do: <<buf::bits, i::size(sz)-integer-signed-little>>
end

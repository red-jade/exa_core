defmodule Exa.BinaryTest do
  use ExUnit.Case
  import Exa.Binary

  doctest Exa.Binary

  # Image tests give this a good workout

  test "nbits" do
    assert 0 = nbits(0)
    assert 1 = nbits(1)
    assert 2 = nbits(3)
    assert 3 = nbits(4)
    assert 3 = nbits(7)
    assert 4 = nbits(8)
    assert 8 = nbits(255)
    assert 9 = nbits(256)
    assert 16 = nbits(65535)
    Enum.each(1..100, fn i -> assert nbits(i) == 1 + floor(:math.log2(i)) end)

    assert 5 = signed_bits(15)
    assert 5 = signed_bits(-16)
    assert 6 = signed_bits(16)
    assert 6 = signed_bits(-17)

    assert 8 = signed_bits(127)
    assert 8 = signed_bits(-128)
    assert 9 = signed_bits(128)
    assert 9 = signed_bits(-129)

    assert 16 = signed_bits(32767)
    assert 16 = signed_bits(-32768)
    assert 17 = signed_bits(32768)
    assert 17 = signed_bits(-32769)
  end

  test "bits'n'bytes" do
    assert <<1::8, 2::8, 3::8>> == from_bytes([1, 2, 3])
    assert [1, 2, 3] == to_bytes(<<1::8, 2::8, 3::8>>)
    assert <<3::8, 2::8, 1::8>> == reverse_bytes(<<1::8, 2::8, 3::8>>)

    assert <<0::1, 1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>> ==
             from_bits([0, 1, 0, 0, 1, 1, 0, 0])

    assert [0, 1, 0, 0, 1, 1, 0, 0] ==
             to_bits(<<0::1, 1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>>)

    assert <<0::1, 0::1, 1::1, 1::1, 0::1, 0::1, 1::1, 0::1>> ==
             reverse_bits(<<0::1, 1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>>)

    assert "010" == 2 |> from_uint(3) |> to_bitstr()
    assert "111" == 7 |> from_uint() |> to_bitstr()

    assert <<0::1, 1::1, 1::1>> == from_bitstr("011") 
    assert 3 == to_uint(<<0::1, 1::1, 1::1>>)

    assert 99 == 99 |> from_uint() |> to_bitstr() |> from_bitstr() |> to_uint()

    assert 76 == to_uint(<<0::1, 1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>>)
    assert <<0::1, 1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>> == from_uint(76, 8)
    assert <<1::1, 0::1, 0::1, 1::1, 1::1, 0::1, 0::1>> == from_uint(76)
  end

  test "imid" do
    avg(0, 0)
    avg(0, 6)
    avg(0, 5)
    avg(-6, 0)
    avg(-5, 0)
    avg(-10, -5)
    avg(-11, -5)
  end

  test "padded bits/bytes" do
    assert 0 == padded_bits(0)
    assert 1 == padded_bits(3)
    assert 1 == padded_bits(7)
    assert 2 == padded_bits(9)
    assert 2 == padded_bits(16)
    assert 3 == padded_bits(17)

    assert 0 == pad_bits(0)
    assert 5 == pad_bits(3)
    assert 1 == pad_bits(7)
    assert 0 == pad_bits(8)
    assert 7 == pad_bits(9)
    assert 0 == pad_bits(16)
    assert 4 == pad_bits(20)

    assert 1 = pad_bytes(13, 2)
    assert 1 = pad_bytes(23, 4)
    assert 5 = pad_bytes(43, 8)
    assert 13 = pad_bytes(99, 16)
  end

  defp avg(imin, imax) do
    expect = ((imax + imin) / 2) |> ceil() |> trunc()
    assert expect == imid(imin, imax)
  end

  test "nset bits" do
    # round up/down the nbits a little to avoid multiples of 4
    do_nset(0..7, 3)
    do_nset(8..255, 11)
    do_nset(256..1_024, 15)
  end

  defp do_nset(range, nb) do
    Enum.each(range, fn i ->
      b = <<i::size(nb)>>
      n = b |> to_bits() |> Enum.sum()
      assert nset(i) == n
      assert nset(b) == n
    end)
  end
end

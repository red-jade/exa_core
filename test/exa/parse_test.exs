defmodule Exa.ParseTest do
  use ExUnit.Case
  import Exa.Types
  import Exa.Parse

  doctest Exa.Parse

  test "nil" do
    par = null()

    assert is_nil(par.(""))
    assert is_nil(par.("null"))

    assert "foo" == par.("foo")
  end

  test "atom" do
    par = atom(["foo", "bar", "with_space"])

    assert is_nil(par.(nil))
    assert nil == par.("")
    assert "zoo" == par.("zoo")

    assert :foo == par.("foo")
    assert :bar == par.("bar")

    assert :foo == par.(" foo ")
    assert :bar == par.("BAR")

    assert :with_space == par.("With Space")

    assert "baz" == par.("baz")
  end

  test "bool" do
    par = bool()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert true == par.("true")
    assert true == par.("TRUE")
    assert true == par.("T")

    assert false == par.("false")
    assert false == par.("FALSE")
    assert false == par.("F")

    assert "baz" == par.("baz")

    par = bool(["1"], ["0"])

    assert true == par.("1")
    assert false == par.("0")

    assert "true" == par.("true")
    assert "10" == par.("10")
  end

  test "int" do
    par = int()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert 1 == par.("1")
    assert 4356 == par.("4356")
    assert -23 == par.("-23")

    assert "3.14" == par.("3.14")
    assert "1.0E4" == par.("1.0E4")
  end

  test "hex" do
    par = hex()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert 1 == par.("1")
    assert 16 == par.("10")
    assert -32 == par.("-20")
    assert 34 == par.("0x22")
    assert 8704 == par.("\\u2200")

    assert "3.14" == par.("3.14")
    assert "1.0E4" == par.("1.0E4")
  end

  test "float" do
    par = float()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert 1.0 == par.("1")
    assert 10.0 == par.("10")
    assert -20.1 == par.("-20.1")

    assert 1.0e4 == par.("1.0E4")

    assert 2.0e-2 == par.("2e-2")
  end

  test "date" do
    par = date()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert ~D[2023-12-25] == par.("2023-12-25")

    assert "2023-99-25" == par.("2023-99-25")
  end

  test "time" do
    par = time()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert ~T[08:32:54] == par.("08:32:54")
    assert ~T[08:32:54.123] == par.("08:32:54.123")
    assert ~T[23:32:54.123] == par.("T23:32:54.123Z")

    assert "11:22:99" == par.("11:22:99")
    assert "2023-99-25" == par.("2023-99-25")
  end

  test "naive datetime" do
    par = naive_datetime()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert ~N[2023-12-25T11:22:33] == par.("2023-12-25 11:22:33Z")
    assert ~N[2023-12-25T08:32:54.123] == par.("2023-12-25T08:32:54.123+02:00")

    assert "2023-12-25" == par.("2023-12-25")
    assert "11:22:33" == par.("11:22:33")
    assert "2023-99-25 25:12:34" == par.("2023-99-25 25:12:34")
  end

  test "datetime" do
    par = datetime()

    assert is_nil(par.(nil))
    assert "" == par.("")
    assert "foo" == par.("foo")

    assert {~U[2023-12-25T11:22:33Z], 0} == par.("2023-12-25 11:22:33Z")
    assert {~U[2023-12-25T08:32:54.123Z], 0} == par.("2023-12-25T08:32:54.123Z")
    assert {~U[2023-12-25T06:32:54.123Z], 7200} == par.("2023-12-25T08:32:54.123+02:00")

    # must be a timezone or offset indication
    assert "2023-12-25 11:22:33" == par.("2023-12-25 11:22:33")
    assert "2023-12-25" == par.("2023-12-25")
    assert "11:22:33" == par.("11:22:33")
    assert "2023-99-25 25:12:34" == par.("2023-99-25 25:12:34")
  end

  test "email" do
    par = email()

    assert is_nil(par.(nil))

    assert is_string(par.("example@foo.com"))
    assert is_string(par.("'example'@foo.com"))
    assert is_string(par.("exa.mple-{cool!}@foo-bar.baz.com"))

    assert {:error, _} = par.("examplefoo.com")
    assert {:error, _} = par.("example@foocom")
    assert {:error, _} = par.(".example@foo.com")
    assert {:error, _} = par.("example.@foo.com")
    assert {:error, _} = par.("exa..mple@foo.com")
    assert {:error, _} = par.("(example)@foo.com")
    assert {:error, _} = par.("example@foo.c")
  end

  test "guess" do
    par = guess()

    assert is_nil(par.("null"))

    assert true == par.("true")
    assert false == par.("f")

    assert 42 == par.("42")
    assert -99 == par.("-99")

    assert 3.14 == par.("3.14")
    assert -273.1 == par.("-273.1")
    assert 6.2e23 == par.("6.2E23")

    assert ~D[2023-12-25] == par.("2023-12-25")
    assert ~T[08:32:54] == par.("08:32:54")
    assert ~N[2023-12-25T11:22:33] == par.("2023-12-25 11:22:33")
    assert {~U[2023-12-25T10:22:33Z], 3600} == par.("2023-12-25 11:22:33+01:00")

    # assert {{3, 45, 0.0, :S}, {2, 12, 15.0, :E}} == par.("3°45'0.0\"S 2°12'15.0\"E")
    # assert {{3.75, :N}, {2.20417, :W}} == par.("3.75 N 2.20417 W")

    assert "foo" == par.("foo")
  end

  test "array" do
    par = array()

    assert [""] == par.("")

    assert ["foo", "bar", "baz"] == par.("foo,bar,baz")
    assert ["foo", "bar", "baz"] == par.("foo, bar, baz")
    assert ["foo", "bar", "baz"] == par.(" foo ,\n bar ,\n baz ")
    assert ["foo bar", "baz"] == par.(" foo bar , baz")

    par = array(delim: "/", parnull: null(), filter: false)

    assert [nil] == par.("")

    assert ["foo", "bar", "baz"] == par.("foo/bar/baz")
    assert ["foo, bar, baz"] == par.("foo, bar, baz")
    assert ["foo", nil, nil, nil, "bar"] == par.("foo//null/NaN/bar")

    par = array(delim: [":", ";"], parnull: null(), filter: true)

    assert [] == par.("")

    assert ["foo", "bar", "baz"] == par.("foo:bar;baz")
    assert ["foo", "bar"] == par.("foo::null;NaN;bar")

    par = array(delim: ":", parnull: null(), filter: false, pardata: int())

    assert [nil] == par.("")

    assert ["foo", "bar", "baz"] == par.("foo:bar:baz")
    assert ["foo", 0, 1, "3.14", -1, 435, -987] == par.("foo :0:1: 3.14 : -1 : 435 : -987")
  end
end

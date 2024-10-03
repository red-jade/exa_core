defmodule Exa.ProcessTest do
  use ExUnit.Case
  import Exa.Process

  doctest Exa.Process

  test "ipid" do
    ipid = ipid()
    assert is_integer(ipid)
  end

  test "simple" do
    self = self()

    ns = [:exa, :graph]
    assert :exa_graph == key(ns)

    name = "foo"

    assert register!(ns, name, self)
    assert_raise ArgumentError, fn -> register!(ns, name, self()) end

    assert self == whereis!(ns, name)
    assert_raise ArgumentError, fn -> whereis!(ns, "xyz") end

    assert unregister!(ns, name)
    assert_raise ArgumentError, fn -> unregister!(ns, name) end
    assert_raise ArgumentError, fn -> unregister!(ns, "xyx") end
  end

  test "map timeout" do
    n = 1_000_000

    for timeout <- [50, 1_000] do
      is = Range.to_list(1..n)
      start = Exa.Stopwatch.start()
      result = map(is, fn i -> Exa.Math.sind(i / 1000.0) end, timeout)
      elapsed = Exa.Stopwatch.elapsed(start) / 1000.0

      case result do
        {:timeout, xs} ->
          IO.inspect(elapsed, label: "timeout")
          assert length(xs) < n
          assert elapsed > timeout

        xs when is_list(xs) ->
          IO.inspect(elapsed, label: "complete")
          assert length(xs) == n
          assert elapsed < timeout
      end
    end
  end

  test "reduce timeout" do
    n = 1_000_000

    for timeout <- [50, 1_000] do
      is = Range.to_list(1..n)
      start = Exa.Stopwatch.start()
      result = reduce(is, 0.0, fn i, acc -> acc + Exa.Math.sind(i / 1000.0) end, timeout)
      elapsed = Exa.Stopwatch.elapsed(start) / 1000.0

      case result do
        {:timeout, _acc} ->
          IO.inspect(elapsed, label: "timeout")
          assert elapsed > timeout

        _acc ->
          IO.inspect(elapsed, label: "complete")
          assert elapsed < timeout
      end
    end
  end
end

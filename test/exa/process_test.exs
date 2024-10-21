defmodule Exa.ProcessTest do
  use ExUnit.Case
  import Exa.Process
  import Exa.Exec

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

  @tag timeout: 20_000
  test "map timeout" do
    for {fun, n} <- [{&Exa.Process.tmap/3, 300}, {&Exa.Exec.pmap/3, 100_000}] do
      for timeout <- [20, 5_000] do
        start = Exa.Stopwatch.start()
        result = fun.(1..n, &slow_sind/1, timeout)
        elapsed = Exa.Stopwatch.elapsed_ms(start)

        case result do
          {:timeout, xs} ->
            IO.inspect(elapsed, label: "timeout  map")
            assert length(xs) < n
            assert elapsed >= timeout

          {:ok, xs} when is_list(xs) ->
            IO.inspect(elapsed, label: "complete map")
            assert length(xs) == n
            # assert elapsed < timeout
        end
      end
    end

    result = tmap(1..100, &sind!/1)
    assert {:error, _err} = result

    result = pmap(1..100, &sind!/1)
    assert {:error, _err} = result
  end

  test "reduce timeout" do
    for timeout <- [50, 2_000] do
      start = Exa.Stopwatch.start()
      result = treduce(1..500_000, 0.0, &sind/2, timeout)
      elapsed = Exa.Stopwatch.elapsed_ms(start)

      case result do
        {:timeout, _acc} ->
          IO.inspect(elapsed, label: "timeout  treduce")
          assert elapsed >= timeout

        _ok_acc ->
          IO.inspect(elapsed, label: "complete treduce")
          assert elapsed < timeout
      end
    end

    result = treduce(1..100, 0.0, &sind!/2)
    assert {:error, _err} = result

    for timeout <- [50, 2_000] do
      start = Exa.Stopwatch.start()
      result = pmap_reduce(1..100_000, 0.0, &sind/1, &Kernel.+/2, timeout)
      elapsed = Exa.Stopwatch.elapsed_ms(start)

      case result do
        {:timeout, _acc} ->
          IO.inspect(elapsed, label: "timeout  preduce")
          assert elapsed >= timeout

        _ok_acc ->
          IO.inspect(elapsed, label: "complete preduce")
          assert elapsed < timeout
      end
    end

    result = pmap_reduce(1..100, 0.0, &sind!/1, &Kernel.+/2)
    assert {:error, _err} = result
  end

  defp sind(i), do: Exa.Math.sind(i / 1000.0)

  defp sind(i, acc), do: acc + Exa.Math.sind(i / 1000.0)

  defp sind!(97), do: raise(RuntimeError)
  defp sind!(i), do: Exa.Math.sind(i / 1000.0)

  defp sind!(97, _acc), do: raise(RuntimeError)
  defp sind!(i, acc), do: acc + Exa.Math.sind(i / 1000.0)

  defp slow_sind(i) do
    Process.sleep(1)
    Exa.Math.sind(i / 1000.0)
  end
end

defmodule Exa.StopwatchTest do
  use ExUnit.Case
  import Exa.Stopwatch

  doctest Exa.Stopwatch

  test "elapsed" do
    start = start()
    Process.sleep(1_000)
    dt = elapsed(start)
    assert start > 0
    assert dt > 1_000
  end

  test "execute" do
    fun = fn -> Enum.map(1..5_000, fn i -> :math.sqrt(1.0 * i) end) end
    {_, metrix} = execute(fun, 10)
    IO.inspect(metrix)
  end
end

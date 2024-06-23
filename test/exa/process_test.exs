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
end

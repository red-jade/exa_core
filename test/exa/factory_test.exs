defmodule Exa.FactoryTest do
  use ExUnit.Case
  import Exa.Factory

  defmodule P2D do
    @enforce_keys [:x, :y]
    defstruct [:x, :y]
  end

  defmodule XY do
    @enforce_keys [:x, :y]
    defstruct [:x, :y]
  end

  doctest Exa.Factory

  test "struct keys" do
    assert [:calendar, :day, :month, :year] == Enum.sort(struct_keys(Date))
    assert [:x, :y] == struct_keys(P2D)
  end

  test "factory" do
    fac_fun = factory([Date, P2D])

    assert {:struct, %P2D{:x => 1, :y => 2}} == fac_fun.(x: 1, y: 2)

    assert_raise ArgumentError, fn -> factory([P2D, XY]) end
  end
end

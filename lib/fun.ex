defmodule Exa.Fun do
  @moduledoc "Utilities for functions."

  alias Exa.Types, as: E

  # -----
  # types
  # -----

  # safe mapper is wrapped in ok/error tuple
  @type safe_mapper(a, b) :: E.mapper([a], E.result(b))

  # safe reducer is wrapped in ok/error tuple
  @type safe_reducer(acc) :: (list() -> E.result(acc))

  # ------
  # errors
  # ------

  defmodule ReturnValueError do
    defexception [:reason]

    def message(e) do
      "Function returned an error reason: #{e.reason}"
    end
  end

  defmodule ReturnValueTimeout do
    defexception [:partial]

    def message(e) do
      "Function timed out. Partial result: #{inspect(e.partial)}"
    end
  end

  # ----------------
  # public functions
  # ----------------

  @doc """
  Handle an ok/error/timeout return value and raise an error on failure.
  """
  @spec success(E.tresult(t)) :: t when t: var
  def success!({:ok, val}), do: val
  def success!({:error, err}), do: raise(ReturnValueError, reason: err)
  def success!({:timeout, val}), do: raise(ReturnValueTimeout, partial: val)

  @doc """
  Wrap an ok/error function in a raising wrapper.
  Throw an error on failure.

  The new function expects arguments as a list.
  """
  @spec success(fun()) :: (list() -> any()) when t: var
  def success(fun) do
    fn args -> success!(apply(fun, args)) end
  end

  @doc """
  Wrap a plain value function in a safe wrapper.

  The new function expects arguments as a list.
  """
  @spec safe(fun()) :: (list() -> E.result(any()))
  def safe(fun) do
    fn args ->
      try do
        {:ok, apply(fun, args)}
      rescue
        err -> {:error, err}
      end
    end
  end
end

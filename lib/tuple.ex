defmodule Exa.Tuple do
  @moduledoc """
  Tuple utilities.

  It is expected that the module is not imported or aliased,
  but all functions are called with the full path, e.g. `Exa.Tuple.min`.
  """

  alias Exa.Text, as: T
  alias Exa.Text

  import Exa.Types
  alias Exa.Types, as: E

  @doc "Set the element of a tuple."
  @spec set(tuple(), E.tuple_index(), any()) :: tuple()
  def set(tup, i, val) when is_tuple_index(tup, i), do: :erlang.setelement(i + 1, tup, val)

  @doc "Sum a tuple of numbers."
  @spec sum(tuple()) :: number()
  def sum(tup) when is_tuple_nonempty(tup), do: reduce(tup, 0, &Kernel.+/2)

  @doc "Minimum value of a non-empty tuple."
  @spec min(tuple()) :: any()
  def min(tup) when is_tuple_nonempty(tup), do: reduce(tup, &Kernel.min/2)

  @doc "Maximum value of a non-empty tuple."
  @spec max(tuple()) :: any()
  def max(tup) when is_tuple_nonempty(tup), do: reduce(tup, &Kernel.max/2)

  @doc """
  Exists over a tuple.
  Empty tuple returns `false`.
  """
  @spec any?(tuple(), E.predicate?(any)) :: bool()
  def any?(tup, pred) when is_tuple(tup) and is_function(pred, 1) do
    reduce(tup, false, fn t, any -> any or pred.(t) end)
  end

  @doc """
  Forall over a tuple.
  Empty tuple returns `true`.
  """
  @spec all?(tuple(), E.predicate?(any)) :: bool()
  def all?(tup, pred) when is_tuple(tup) and is_pred(pred) do
    reduce(tup, true, fn t, all -> all and pred.(t) end)
  end

  @doc """
  Sort a list of tuples by the given indexed element values.

  All members of the list must be tuples.
  The index must be valid for all tuples in the list.
  """
  @spec sort([tuple()], E.tuple_index()) :: [tuple()]

  def sort([], _i), do: []

  def sort([h | _] = ts, i) when is_list(ts) and is_tuple_index(h, i) do
    Enum.sort(ts, fn t1, t2 -> elem(t1, i) < elem(t2, i) end)
  end

  @doc """
  Get the tuple with the minimum indexed element value,
  from a non-empty list of tuples.

  Fails for empty list.
  All members of the list must be tuples.
  The index must be valid for every tuple in the list.
  """
  @spec minimum([tuple(), ...], E.tuple_index()) :: tuple()
  def minimum([t0 | ts], i) when is_tuple_index(t0, i) do
    Enum.reduce(ts, t0, fn
      t1, t2 when elem(t1, i) < elem(t2, i) -> t1
      _, t2 -> t2
    end)
  end

  @doc """
  Get the tuple with the maximum value for an indexed element,
  from a non-empty list of tuples.

  Fails for empty list.
  All members of the list must be tuples. 
  The index must be valid for every tuple in the list.
  """
  @spec maximum([tuple(), ...], E.tuple_index()) :: tuple()
  def maximum([t0 | ts], i) when is_tuple_index(t0, i) do
    Enum.reduce(ts, t0, fn
      t1, t2 when elem(t1, i) > elem(t2, i) -> t1
      _, t2 -> t2
    end)
  end

  @doc """
  Filter a tuple list to match an indexed element with a predicate function.

  All members of the list must be tuples. 
  The index must be valid for every tuple in the list.
  """
  @spec filter([tuple()], E.tuple_index(), E.predicate(any())) :: [tuple()]

  def filter([], _i, _fun), do: []

  def filter([h | _] = ts, i, fun) when is_list(ts) and is_tuple_index(h, i) and is_pred(fun) do
    Enum.filter(ts, fn t -> fun.(elem(t, i)) end)
  end

  @doc "Map over a tuple."
  @spec map(tuple(), E.mapper(any(), any())) :: tuple()

  def map({p, q}, fun), do: {fun.(p), fun.(q)}

  def map({p, q, r}, fun), do: {fun.(p), fun.(q), fun.(r)}

  def map(tup, fun) when is_tuple_nonempty(tup) do
    0..(tuple_size(tup) - 1)
    |> Enum.map(&fun.(elem(tup, &1)))
    |> List.to_tuple()
  end

  @doc """
  Pointwise (dot) map a sequence of functions over a tuple.
  Require the list of funs to be the same length as the tuple.
  """
  @spec maps(tuple(), [function()]) :: tuple
  def maps(tup, funs) when is_tuple(tup) and is_list(funs) and length(funs) == tuple_size(tup) do
    tmaps(tup, Enum.reverse(funs), tuple_size(tup) - 1, [])
  end

  defp tmaps(_, [], -1, vals), do: List.to_tuple(vals)

  defp tmaps(tup, [fun | funs], i, vals) do
    tmaps(tup, funs, i - 1, [fun.(elem(tup, i)) | vals])
  end

  @doc """
  Pointwise (dot) map a sequence of functions over a tuple,
  then reduce the results to a single value.
  Require the list of funs to be the same length as the tuple.
  """
  @spec maps_reduce(tuple(), [function()], acc, E.reducer(any(), acc)) :: acc when acc: var
  def maps_reduce(tup, funs, init, merge) do
    # TODO - should fuse this into a single pass
    # but leave it slow 'n'easy for now
    reduce(maps(tup, funs), init, merge)
  end

  @doc "Fold over a tuple."
  @spec reduce(tuple(), acc, E.reducer(any(), acc)) :: acc when acc: var
  def reduce(tup, init, fun) when is_tuple_nonempty(tup) and is_reducer(fun) do
    0..(tuple_size(tup) - 1)
    |> Enum.reduce(init, fn i, acc -> fun.(elem(tup, i), acc) end)
  end

  @doc "Fold over a tuple, using first element as the initial value."
  @spec reduce(tuple(), E.reducer(any(), acc)) :: acc when acc: var
  def reduce(tup, fun) when is_tuple_nonempty(tup) and is_reducer(fun) do
    1..(tuple_size(tup) - 1)
    |> Enum.reduce(elem(tup, 0), fn i, acc -> fun.(elem(tup, i), acc) end)
  end

  @doc "Fold over two equal-length tuples."
  @spec bireduce(tuple(), tuple(), acc, E.bireducer(any(), acc)) :: acc when acc: var
  def bireduce(t1, t2, init, fun)
      when is_tuple_nonempty(t1) and is_tuple_nonempty(t2) and
             tuple_size(t1) == tuple_size(t2) and is_bireducer(fun) do
    0..(tuple_size(t1) - 1)
    |> Enum.reduce(init, fn i, acc -> fun.(elem(t1, i), elem(t2, i), acc) end)
  end

  @doc """
  Combine two tuples.

  The lengths of the input tuples must be the same.
  The result is a list of tuple pairs
  containing the two corresponding input values.
  """
  @spec zip(tuple(), tuple()) :: [{any(), any()}]
  def zip(t1, t2) when is_tuple(t1) and is_tuple(t2) and tuple_size(t1) == tuple_size(t2) do
    Enum.map(0..(tuple_size(t1) - 1), fn i -> {elem(t1, i), elem(t2, i)} end)
  end

  @doc """
  Zip a function over a pair of tuples 
  applying the function to each pair of elements
  and returning a list of results. 
  The result is the length of the shortest input.
  Semantically equivalent to:
    `List.zip( Tuple.to_list(t1), Tuple.to_list(t2) )`
    `|> Enum.map( fn {a,b} -> fun.(a,b) end )`
  """
  @spec zip_map(tuple(), tuple(), E.bimapper(any(), b)) :: [b] when b: var
  def zip_map(t1, t2, fun) when is_tuple(t1) and is_tuple(t2) and is_bimapper(fun) do
    tzip(t1, t2, fun, min(tuple_size(t1), tuple_size(t2)) - 1, [])
  end

  defp tzip(_, _, _, -1, acc), do: acc

  defp tzip(t1, t2, fun, i, acc) do
    tzip(t1, t2, fun, i - 1, [fun.(elem(t1, i), elem(t2, i)) | acc])
  end

  @doc """
  Combine two tuples with a pointwise binary function.

  The result has the length of the shortest tuple input.

  The result is a tuple 
  where each element is the binary combination 
  of the two corresponding input values.
  """
  @spec zip_with(tuple(), tuple(), E.bimapper(any(), any())) :: tuple()
  def zip_with(tup1, tup2, fun)
      when is_tuple(tup1) and is_tuple(tup2) and
             tuple_size(tup1) == tuple_size(tup2) and is_bimapper(fun) do
    0..(tuple_size(tup1) - 1)
    |> Enum.map(fn i -> fun.(elem(tup1, i), elem(tup2, i)) end)
    |> List.to_tuple()
  end

  @doc "Dot product of two number tuples with the same length."
  @spec dot(tuple(), tuple()) :: tuple()
  def dot({x1, y1}, {x2, y2}), do: {x1 * x2, y1 * y2}
  def dot({x1, y1, z1}, {x2, y2, z2}), do: {x1 * x2, y1 * y2, z1 * z2}
  def dot(t1, t2), do: zip_with(t1, t2, &Kernel.*/2)

  # to_string protocol ----------

  defimpl String.Chars, for: Tuple do
    # This version is faster than term_to_string(tup)
    # because it does everything in one pass with no reversal.
    # Note that we count down through the tuple
    # to build the list in reverse order.

    @spec to_string(tuple()) :: String.t()

    def to_string({}), do: "{}"

    def to_string(tup) when is_tuple(tup) do
      n = tuple_size(tup)
      tstr(tup, n - 2, [Text.term_to_text(elem(tup, n - 1)), ?}])
    end

    @spec tstr(tuple(), integer(), T.textlist()) :: String.t()
    defp tstr(_, -1, text), do: List.to_string([?{ | text])
    defp tstr(tup, i, text), do: tstr(tup, i - 1, [Text.term_to_text(elem(tup, i)), ?, | text])
  end
end

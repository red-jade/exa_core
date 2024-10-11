defmodule Exa.List do
  @moduledoc "Utilities for Lists."

  import Exa.Types
  alias Exa.Types, as: E

  @typedoc "Error when list elements are not equal."
  @type mismatch() ::
          {:neq, index :: E.index0(), elem1 :: any(), elem2 :: any()}
          | {:len, excess1 :: list(), excess2 :: list()}

  @doc """
  Get the last member in a list and the index in one pass.

  If the list is empty, return `{nil, -1}`.

  Equivalent to `{List.last(ls), length(ls)-1}`.

  ## Examples: 
      iex> last([])
      {nil, -1}
      iex> last([1])
      {1, 0}
      iex> last([1,2,3])
      {3, 2}
  """
  @spec last(list()) :: {any(), -1 | E.index0()}
  def last([]), do: {nil, -1}
  def last(ls), do: last(ls, 0)

  defp last([t], i), do: {t, i}
  defp last([_ | tail], i), do: last(tail, i + 1)

  @doc """
  Ensure that a term is a list. 
  If it is not a list then make it a singleton list.

  ## Examples
      iex> enlist( 1) 
      [1]
      iex> enlist( "abc") 
      ["abc"]
      iex> enlist( []) 
      []
      iex> enlist( [1]) 
      [1]
  """
  @spec enlist(any()) :: list()
  def enlist(xs) when is_list(xs), do: xs
  def enlist(x), do: [x]

  @doc """
  Convert singleton list to a value.

  Longer lists remain unchanged.

  Optionally replace empty list with a special value. 
  The default empty value is `nil`.

  ## Examples
      iex> unlist( []) 
      nil
      iex> unlist( [], 0) 
      0
      iex> unlist( [3]) 
      3
      iex> unlist( [1,2,3]) 
      [1,2,3]
  """
  @spec unlist(list(), any()) :: any() | list()
  def unlist(xs, empty \\ nil)
  def unlist([], empty), do: empty
  def unlist([x], _), do: x
  def unlist(xs, _) when is_list(xs), do: xs

  @doc "Wrap a list with new first and last elements."
  @spec wrap([a], a, a) :: [a] when a: var
  def wrap(ps, prefix, suffix) when is_list(ps), do: [prefix | ps] ++ [suffix]

  @doc """
  Compare two lists for equality.

  Return `:eq` or details of the elements that do not match.
  If the list is deeply nested, then return a list of mismatched elements.

  There are two sources of inequality:
  - corresponding elements are not equal
  - length mismatch:
    - first list has additional elements
    - second list has additional elements

  ## Examples:
      iex> compare([1,2,3],[1,2,3])
      :eq
      iex> compare([1,9,3],[1,2,3])
      [{:neq, 1, 9, 2}]
      iex> compare([1,2,3,5],[1,2,3])
      [{:len, [5], []}]
      iex> compare([1,2,3],[1,2,3,7])
      [{:len, [], [7]}]
      iex> compare([1,2,[10,11]],[1,2,[10,99]])
      [{:neq, 2, [10,11], [10,99]}, {:neq, 1, 11, 99}]
  """
  @spec compare(list(), list()) :: :eq | [mismatch()]
  def compare(xs, ys), do: cmp(xs, ys, 0, [])

  @spec cmp(list(), list(), E.index0(), [mismatch()]) :: :eq | [mismatch()]

  defp cmp([x | xs], [x | ys], i, errs), do: cmp(xs, ys, i + 1, errs)

  defp cmp([x | _], [y | _], i, errs) do
    # TODO - number comparison and FP epsilon?
    # TODO - string comparison
    errs = [{:neq, i, x, y} | errs]
    if is_list(x) and is_list(y), do: cmp(x, y, 0, errs), else: Enum.reverse(errs)
  end

  defp cmp([], [], _, _), do: :eq
  defp cmp(xs, [], _, errs), do: Enum.reverse([{:len, xs, []} | errs])
  defp cmp([], ys, _, errs), do: Enum.reverse([{:len, [], ys} | errs])

  @doc "Convert list mismatch results to error strings."
  @spec mismatch(:eq | [mismatch()]) :: IO.chardata()
  def mismatch(ms), do: mis(ms, [])

  defp mis(:eq, []), do: "Equal"
  defp mis([{:neq, i, x, y} | ms], strs), do: mis(ms, ["Error [#{i}]: #{x} != #{y}" | strs])
  defp mis([{:len, xs, []} | ms], strs), do: mis(ms, ["Error: excess 1st list\n#{xs}" | strs])
  defp mis([{:len, [], ys} | ms], strs), do: mis(ms, ["Error: excess 2nd list\n#{ys}" | strs])
  defp mis([], strs), do: Enum.reverse(strs)

  @doc """
  Interleave two lists. 
  Take elements from the first and second lists in turn,
  ending with the last element of the first list.

  Any subsequent elements of the second list are ignored.

  A common case is when the second list has one less element
  than the first list, so the begin/end of the first list
  also bracket the final result. 

  Behaviour is similar to List.intersperse and Enum.join.
  Useful to process `textlist`.

  ## Examples
      iex> interleave( [1,2,3], [8,9]) 
      [1,8,2,9,3]
      iex> interleave( [?4,?6,"10"], [?+,?=]) |> List.to_string
      "4+6=10"
      iex> interleave( [1,2,3], [8,9,7,6,5,4]) 
      [1,8,2,9,3]
  """
  @spec interleave(list(), list()) :: list()
  def interleave(ps, qs) when is_list(ps) and is_list(qs) and length(qs) >= length(ps) - 1 do
    inter(ps, qs, [])
  end

  defp inter([p], _, acc), do: Enum.reverse([p | acc])
  defp inter([p | ps], [q | qs], acc), do: inter(ps, qs, [q, p | acc])

  @doc """
  Partition a list by a predicate. 

  Combine filter and reject into a single pass
  to create two lists of elements:
  the first is those elements that pass the predicate;
  and the second is those that fail.

  ## Examples
      iex> partition( [1,2,3,4,5], &( rem(&1,2) == 0 ) ) 
      { [2,4], [1,3,5] }
  """
  @spec partition(list(a), E.predicate?(a)) :: {list(a), list(a)} when a: var
  def partition(xs, pred) when is_list(xs) and is_pred(pred) do
    part(xs, pred, {[], []})
  end

  defp part([], _, {ps, qs}) do
    {Enum.reverse(ps), Enum.reverse(qs)}
  end

  defp part([x | xs], pred, {ps, qs}) do
    cond do
      pred.(x) -> part(xs, pred, {[x | ps], qs})
      true -> part(xs, pred, {ps, [x | qs]})
    end
  end

  @doc """
  Test if a list contains any duplicates. 

  The empty list does not contain duplicates, so the result is true.
  Behaviour is equivalent to testing `Enum.frequencies` for values > 1,
  or comparing length with that of `Enum.uniq`,
  but this should be more efficient, 
  especially when it can fail fast with an early duplicate.
  ## Examples
      iex> unique?( [] ) 
      true
      iex> unique?( [1,2,3] ) 
      true
      iex> unique?( [1,2,3,2,1] ) 
      false
  """
  @spec unique?(list()) :: bool()
  def unique?(xs) when is_list(xs), do: uniq?(xs, MapSet.new())

  defp uniq?([], _), do: true

  defp uniq?([p | ps], pre) do
    cond do
      MapSet.member?(pre, p) -> false
      true -> uniq?(ps, MapSet.put(pre, p))
    end
  end

  @doc """
  Get the duplicates from a list. 

  Behaviour is equivalent to `Enum.frequencies` filter keys with values > 1.
  The order of the duplicates is not defined.

  ## Examples
      iex> duplicates( [] ) 
      []
      iex> duplicates( [1,2,3] ) 
      []
      iex> duplicates( [1,2,3,2,1] ) |> Enum.sort()
      [1,2]
  """
  @spec duplicates(list()) :: list()
  def duplicates(xs) when is_list(xs), do: dups(xs, MapSet.new(), MapSet.new())

  defp dups([], _, dups), do: MapSet.to_list(dups)

  defp dups([p | ps], pre, dups) do
    cond do
      MapSet.member?(pre, p) -> dups(ps, pre, MapSet.put(dups, p))
      true -> dups(ps, MapSet.put(pre, p), dups)
    end
  end

  @doc """
  Delete the element at an index in a non-empty list.

  Return the new list and the deleted element.

  ## Examples: 
      iex> delete_at([1,2,3], 0)
      {[2, 3], 1}
      iex> delete_at([1,2,3], 1)
      {[1, 3], 2}
      iex> delete_at([1,2,3], 2)
      {[1, 2], 3}
  """
  @spec delete_at(list(), E.index0()) :: {list(), any()}
  def delete_at([h | t], 0), do: {t, h}

  def delete_at(ls, i) when is_index0(i, ls) do
    case Enum.split(ls, i) do
      {pre, [h]} -> {pre, h}
      {pre, [h | post]} -> {pre ++ post, h}
    end
  end

  @doc """
  Remove all occurrences of a value from a list.

  Return a flag to show if any value was removed.

  ## Examples:
      iex> delete_all([],1)
      {:no_match, []}
      iex> delete_all([2, 3, 4],1)
      {:no_match, [2, 3, 4]}
      iex> delete_all([5, 1, 2],1)
      {:ok, [5, 2]}
      iex> delete_all([1, 2, 3, 1, 2, 3, 1],1)
      {:ok, [2, 3, 2, 3]}
  """
  @spec delete_all(list(), any()) :: {:ok | :no_match, list()}
  def delete_all(xs, y), do: del(xs, y, :no_match, [])

  defp del([y | xs], y, _, out), do: del(xs, y, :ok, out)
  defp del([x | xs], y, flag, out), do: del(xs, y, flag, [x | out])
  defp del([], _, flag, out), do: {flag, Enum.reverse(out)}

  @doc """
  Replace an object in a list, maintaining the order.

  The target is the first element for which the filter function is truthy.
  If no element matches, the original list is returned as `:no_match`.

  ## Examples: 
      iex> replace([], &is_float/1, nil)
      {:no_match, []}
      iex> replace([1,2,3], &is_int_even/1, nil)
      {:ok, [1, nil, 3]}
      iex> replace([1,3,5], &is_int_even/1, 7)
      {:no_match, [1, 3, 5]}
  """
  @spec replace(list(), fun(), any()) :: {:ok | :no_match, list()}
  def replace(xs, fun, new) do
    case repl(xs, fun, new, []) do
      :no_match -> {:no_match, xs}
      out -> {:ok, out}
    end
  end

  # optimized: prompt return, tailed reverse/2, no reverse on error
  defp repl([x | xs], fun, new, out) do
    cond do
      fun.(x) -> Enum.reverse([new | out], xs)
      true -> repl(xs, fun, new, [x | out])
    end
  end

  defp repl([], _fun, _new, _out), do: :no_match

  @doc """
  Replace the element at an index in a non-empty list.
  If the replacement is a list, the result is a nested list.

  Raises ArgumentError if the index is out of range.

  ## Examples: 
      iex> replace_at([1,2,3], 0, 9)
      [9, 2, 3]
      iex> replace_at([1,2,3], 1, 7)
      [1, 7, 3]
      iex> replace_at([1,2,3], 2, 5)
      [1, 2, 5]
      iex> replace_at([1,2,3], 2, [5,6])
      [1, 2, [5,6]]
  """
  @spec replace_at(list(), E.index0(), any()) :: list()

  def replace_at([_ | t], 0, x), do: [x | t]

  def replace_at(ls, i, x) when is_index0(i, ls) do
    case Enum.split(ls, i) do
      {pre, [_]} -> pre ++ [x]
      {pre, [_ | post]} -> pre ++ [x | post]
    end
  end

  @doc """
  Replace an element at an index in a non-empty list
  with the elements of an inserted list. 
  The result is the flattened list.

  Raises ArgumentError if the index is out of range.

  ## Examples: 
      iex> replaces_at([1,2,3], 0, [8,9])
      [8, 9, 2, 3]
      iex> replaces_at([1,2,3], 1, [8,9])
      [1, 8, 9, 3]
      iex> replaces_at([1,2,3], 2, [8,9])
      [1, 2, 8, 9]
  """
  @spec replaces_at(list(), E.index0(), list()) :: list()

  def replaces_at(ls, i, [x]), do: replace_at(ls, i, x)

  def replaces_at(ls, 0, xs), do: xs ++ tl(ls)

  def replaces_at(ls, i, xs) when is_index0(i, ls) do
    case Enum.split(ls, i) do
      {pre, [_]} -> pre ++ xs
      {pre, [_ | post]} -> pre ++ xs ++ post
    end
  end

  @doc """
  Insert an element at an index in a list. 
  If the replacement is a list, the result is a nested list.
  If the index is greater than the extent of the list,
  the new element is appended at the end.

  Raises ArgumentError if the index is negative.

  ## Examples: 
      iex> insert_at([1,2,3], 0, 9)
      [9, 1, 2, 3]
      iex> insert_at([1,2,3], 1, 9)
      [1, 9, 2, 3]
      iex> insert_at([1,2,3], 99, 9)
      [1, 2, 3, 9]
      iex> insert_at([1,2,3], 2, [8,9])
      [1, 2, [8,9], 3]
      iex> insert_at([1,2,3], 99, [8,9])
      [1, 2, 3, [8,9]]
  """
  @spec insert_at(list(), E.index0(), any()) :: list()

  def insert_at(ls, 0, x), do: [x | ls]

  def insert_at(ls, i, x) when is_int_pos(i) do
    case Enum.split(ls, i) do
      {pre, []} -> pre ++ [x]
      {pre, post} -> pre ++ [x | post]
    end
  end

  @doc """
  Insert a list of elements at an index in a list. 
  The result is a flattened list.
  If the index is greater than the extent of the list,
  the new element is appended at the end.

  Raises ArgumentError if the index is negative.

  ## Examples: 
      iex> inserts_at([1,2,3], 0, [8,9])
      [8, 9, 1, 2, 3]
      iex> inserts_at([1,2,3], 1, [8,9])
      [1, 8, 9, 2, 3]
      iex> inserts_at([1,2,3], 2, [8,9])
      [1, 2, 8, 9, 3]
      iex> inserts_at([1,2,3], 99, [8,9])
      [1, 2, 3, 8, 9]
  """
  @spec inserts_at(list(), E.index0(), list()) :: list()

  def inserts_at(ls, 0, xs), do: xs ++ ls

  def inserts_at(ls, i, xs) when is_int_pos(i) do
    case Enum.split(ls, i) do
      {pre, []} -> pre ++ xs
      {pre, post} -> pre ++ xs ++ post
    end
  end

  @doc """
  Add an element if it is not already present (set semantics). 

  ## Examples:
      iex> add_unique([],1)
      [1]
      iex> add_unique([2, 3, 4],1)
      [1, 2, 3, 4]
      iex> add_unique([5, 1, 2],2)
      [5, 1, 2]
  """
  @spec add_unique(list(), any()) :: list()
  def add_unique(xs, x) do
    cond do
      x in xs -> xs
      true -> [x | xs]
    end
  end

  @doc """
  Take-while with a chained reduce state.

  Take elements from the front of the list 
  while the function remains truthy in it's first return value.
  Use the second return value to chain state.

  Return the head of the list, the remaining tail of the list 
  and the final state value.
  The element that fails the test
  remains as the head of the tail.

  ## Examples
      iex> take_while( [1,2,3,4], 0, fn x, sum -> {(sum + x) < 0, sum + x} end) 
      {[], [1,2,3,4], 1}
      iex> take_while( [1,2,3,4], 0, fn x, sum -> {(sum + x) < 5, sum + x} end) 
      {[1,2], [3,4], 6}
      iex> take_while( [1,2,3,4], 0, fn x, sum -> {(sum + x) < 100, sum + x} end) 
      {[1,2,3,4], [], 10}
  """
  @spec take_while([any()], any(), (elem :: any(), state :: any() -> {bool(), state :: any()})) ::
          {list(), list(), any()}
  def take_while(xs, init, fun) when is_function(fun, 2), do: take(xs, init, fun, [])

  defp take([x | xs] = tail, state, fun, head) do
    case fun.(x, state) do
      {false, last_state} -> {Enum.reverse(head), tail, last_state}
      {true, new_state} -> take(xs, new_state, fun, [x | head])
    end
  end

  defp take([], state, _fun, head), do: {Enum.reverse(head), [], state}

  @doc """
  Apply repeated `take_while` with chained reduce state.
  The state resets after each chunk.

  Raises an error if the function is not satisfied for a chunk.

  ## Examples
      The example breaks a list into a sequence of runs 
      that do not exceed a sum of 4.
      iex> take_all_while( [1,2,3,4], 0, fn x, sum -> {(sum + x) < 5, sum + x} end) 
      [[1,2], [3], [4]]
  """
  @spec take_all_while([any()], any(), (any(), any() -> {bool(), any()})) :: [[any()]]
  def take_all_while(xs, init, fun) when is_function(fun, 2), do: takes(xs, init, fun, [])

  defp takes([], _init, _fun, chunks), do: Enum.reverse(chunks)

  defp takes(xs, init, fun, chunks) do
    # prevent infinite loop when fun is never satisfied
    case take_while(xs, init, fun) do
      {[], ^xs, _} -> raise ArgumentError, message: "Failed chunk test for: #{xs}"
      {head, tail, _} -> takes(tail, init, fun, [head | chunks])
    end
  end

  @doc """
  Filter and map.

  Similar to a scalar flat_map, 
  but without the crazy enlisting, empty lists and flatten pass.

  Apply a mapper function, but only keep the truthy values
  (i.e. those values not `nil` and not `false`).

  ## Examples
      iex> filter_map([1,2,3,4], fn 
      ...>   x when rem(x,2) == 0 -> x*x
      ...>   _ -> nil
      ...> end)
      [4,16]
  """
  @spec filter_map([a], E.mapper(a, b | nil | false)) :: [b] when a: var, b: var
  def filter_map(xs, mapr) when is_list(xs) and is_mapper(mapr) do
    do_fmap(xs, mapr, [])
  end

  @spec do_fmap([a], E.mapper(a, b | nil | false), [b]) :: [b] when a: var, b: var
  defp do_fmap([x | xs], mapr, ys) do
    case mapr.(x) do
      false -> do_fmap(xs, mapr, ys)
      nil -> do_fmap(xs, mapr, ys)
      y -> do_fmap(xs, mapr, [y | ys])
    end
  end

  defp do_fmap([], _mapr, ys), do: Enum.reverse(ys)

  # --------------------
  # chunked map & reduce
  # --------------------

  @doc """
  Map a function to chunks of a list.

  The list length must be an exact multiple of n.

  Elements are passed to the map function in a list of n elements.
  The result will be a list with 1/n the length of the original.

  ## Examples:
      Add disjoint pairs of numbers:
      iex> map_chunk([1,2,3,4], 2, fn [a,b] -> a + b end)
      [3,7]
  """
  @spec map_chunk(list(), pos_integer(), E.mapper(list(), any())) :: list()
  def map_chunk(xs, n, fun) when n > 0 and rem(length(xs), n) == 0 do
    xs |> Enum.chunk_every(n) |> Enum.map(fun)
  end

  @doc """
  Map a function on a sliding window over a list.

  The list length must be at least n.

  Elements are passed to the map function in a list of n elements.
  The result will be a new list with `length - n + 1` elements.

  ## Examples:
      Add overlapping pairs of numbers:
      iex> map_slide([1,2,3,4], 2, fn [a,b] -> a + b end)
      [3, 5, 7]
  """
  @spec map_slide(list(), pos_integer(), E.mapper(list(), any())) :: list()
  def map_slide(xs, n, fun) when n > 0 and length(xs) >= n do
    mslide(xs, n, fun, [])
  end

  defp mslide(xs, n, fun, out) when length(xs) >= n do
    mslide(tl(xs), n, fun, [fun.(Enum.take(xs, n)) | out])
  end

  defp mslide(_, _n, _fun, out), do: Enum.reverse(out)

  @doc """
  Reduce a function over chunks of a list.

  The list length must be an exact multiple of n.

  Elements are passed to the reduce function in a list of n elements.
  The result will be the final function result.

  ## Examples:
      Sum ratios of disjoint pairs of integers:
      iex> reduce_chunk([9,3,4,2], 2, 0.0, fn [a,b], z -> z + a/b end)
      5.0
  """
  @spec reduce_chunk(list(), pos_integer(), any(), E.reducer(list(), any())) :: any()
  def reduce_chunk(xs, n, init, fun) when n > 0 and rem(length(xs), n) == 0 do
    xs |> Enum.chunk_every(n) |> Enum.reduce(init, fun)
  end

  @doc """
  Reduce a function over chunks of a list.
  Complete promptly if a halting condition is met. 

  The list length must be an exact multiple of n.

  Elements are passed to the reduce function in a list of n elements.
  The result will be the halting value, or the final continue result.

  ## Examples:
      Sum ratios of disjoint pairs of integers,
      but only while the pairs have decreasing value (ratio > 1.0):
      iex> reduce_chunk_while([6,3,4,2,5,7,12,4], 2, 0, fn 
      ...>   [a,b], z when a > b -> {:cont, z + a/b}
      ...>   _, z -> {:halt, z}
      ...> end)
      4.0
  """
  @spec reduce_chunk_while(list(), pos_integer(), any(), E.while_reducer(list(), any())) :: any()
  def reduce_chunk_while(xs, n, init, fun) when n > 0 and rem(length(xs), n) == 0 do
    xs |> Enum.chunk_every(n) |> Enum.reduce_while(init, fun)
  end

  @doc """
  Reduce a function on a sliding window over a list.

  The list length must be at least n.

  Elements are passed to the reduce function in a list of n elements.
  The result will be the final function value.

  ## Examples:
      iex> reduce_slide([24,12,6,3,1], 2, 0.0, fn [a,b], z -> z + a/b end)
      9.0
  """
  @spec reduce_slide(list(), pos_integer(), any(), E.reducer(list(), any())) :: any()
  def reduce_slide(xs, n, init, fun) when n > 0 and length(xs) >= n do
    rslide(xs, n, init, fun)
  end

  defp rslide(xs, n, state, fun) when length(xs) >= n do
    rslide(tl(xs), n, fun.(Enum.take(xs, n), state), fun)
  end

  defp rslide(_, _n, state, _fun), do: state

  @doc """
  Reduce a function on a sliding window over a list,
  until a halting condition is satisfied.

  The list length must be at least n.

  Elements are passed to the reduce function in a list of n elements.
  The result will be the halting value, or the final continue result.
  """
  @spec reduce_slide_while(list(), pos_integer(), any(), E.while_reducer(list(), any())) :: any()
  def reduce_slide_while(xs, n, init, fun) when n > 0 and length(xs) >= n do
    rslidew(xs, n, init, fun)
  end

  defp rslidew(xs, n, state, fun) when length(xs) >= n do
    case fun.(Enum.take(xs, n), state) do
      {:cont, new_state} -> rslidew(tl(xs), n, new_state, fun)
      {:halt, new_state} -> new_state
    end
  end

  defp rslidew(_xs, _n, state, _fun), do: state
end

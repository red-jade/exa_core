defmodule Exa.Combine do
  @moduledoc """
  Ordering of sequences: permutations, combinations and selections.
  """
  use Exa.Constants
  import Exa.Types
  alias Exa.Types, as: E

  @doc """
  Number of permutations of a list.

  For a list of length `n`, the number of permutations will be `n!`.

  Note that if there are repeated values in the list,
  not all the permutations will be unique.
  The calculation gives all permutations, 
  it does not attempt to identify distinct permutations.

  ## Examples
      iex> nperms([1,2,3,4])
      24
      iex> nperms([])
      1
  """
  @spec nperms(list()) :: pos_integer()
  def nperms(ls) when is_list(ls), do: Exa.Math.fac(length(ls))

  @doc """
  Get all permutations of a list.

  For a list of length `n`, the number of permutations will be `n!`.

  If the list is empty, there will be one permutation, 
  which is just the empty list.

  ## Examples

      iex> permutations([1,2,3])
      [[1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]]

      iex> permutations([])
      [[]]
  """
  @spec permutations(list()) :: [list()]
  def permutations([]), do: [[]]
  def permutations(ls), do: for(h <- ls, t <- permutations(ls -- [h]), do: [h | t])

  @doc """
  Reduce over all permutations of a list.

  If the list is empty, there are no invocations of the reducer,
  and the result is just the initial value.

  The reducer is invoked for each full permutation.
  """
  @spec reduce_perms(list(), a, E.terminator!(list(), a)) :: a when a: var
  def reduce_perms(ls, init, redr) when is_list(ls) and is_reducer(redr) do
    Enum.reduce(ls, init, fn h, acc ->
      Enum.reduce(permutations(ls -- [h]), acc, fn t, acc -> redr.([h | t], acc) end)
    end)
  end

  @doc """
  Find a permutation and return promptly if a target is found.

  The terminator function should throw `{:return, result`} on successful match.

  Return either:
  - `{:ok, result}` the prompt result value thrown by the terminator function
  - `{:no_match, final_accumulator}` if the search completed unsuccessfully
  """
  @spec find_permutation(list(), a, E.terminator!(list(), a)) :: {:ok, any()} | {:no_match, a}
        when a: var
  def find_permutation(ls, init, terminate!) when is_list(ls) and is_terminator(terminate!) do
    {:no_match, reduce_perms(ls, init, terminate!)}
  catch
    {:return, result} -> {:ok, result}
  end

  @doc """
  Get the number of all permutations from a List of Lists (LoL).

  Each sublist is permuted and combined in sequence
  with all the other sub-permutations.

  The number of possibilities is 
  the product of the factorials of all lengths of input sublists.

  If the LoL contains an empty list
  it is effectively ignored (`0! == 1`).

  ## Examples:
      iex> nsubperms([[1,2], [3,4,5]])
      12
      iex> nsubperms([[1,2,3,4,5], []])
      120
  """
  @spec nsubperms([list()]) :: [list()]
  def nsubperms(lol) when is_list(lol) do
    Enum.reduce(lol, 1, fn ls, n -> n * Exa.Math.fac(length(ls)) end)
  end

  @doc """
  Get concatenations of all permutations from a List of Lists (LoL).

  Each sublist is permuted and combined in sequence
  with all the other sub-permutations.

  The result is another List of Lists, where:
  - all the lists have the same length,
    equal to the flattened length of the input LoL.
  - the number of lists is equal to `nsubperms/1`,
    which is the product of factorials of lengths

  If the LoL contains an empty list
  it is effectively ignored.

  ## Examples:

      iex> subpermutations([[1,2], [3,4]])
      [[1,2,3,4], [1,2,4,3], [2,1,3,4], [2,1,4,3]]

      iex> subpermutations([[1,2], []])
      [[1,2], [2,1]]
  """
  @spec subpermutations([list()]) :: [list()]

  def subpermutations([hs | ts]) do
    for h <- permutations(hs), t <- subpermutations(ts), do: List.flatten([h | t])
  end

  def subpermutations([]), do: [[]]

  @doc """
  Get the number of selections for a List of Lists (LoL).

  A selection takes one value from each list in the sequence.

  The result will be the product of all lengths in the original LoL.
  If there is any empty list in the sequence, 
  the result will be zero.

  ## Examples
      iex> nselects([[1,2], [3,4]])
      4
      iex> nselects([[1,2], []])
      0
  """
  @spec nselects([list()]) :: non_neg_integer()
  def nselects(lol), do: do_nsel(lol, 1)

  @spec do_nsel([list()], non_neg_integer()) :: non_neg_integer()
  defp do_nsel([[] | _], _n), do: 0
  defp do_nsel([hs | ts], n), do: do_nsel(ts, n * length(hs))
  defp do_nsel([], n), do: n

  @doc """
  Get all ordered selections taken from a List of Lists (LoL).

  A selection takes one value from each list in the sequence.

  The length of each result will be the length of the original LoL.

  The number of results will be the product of all lengths in the original LoL.

  If there is an empty list in the LoL input,
  the result will be the empty list.

  ## Examples

      iex> selections([[1,2], [3,4]])
      [[1,3], [1,4], [2,3], [2,4]]

      iex> selections([[1,2], []])
      []
  """
  @spec selections([list()]) :: [list()]
  def selections([]), do: [[]]
  def selections([hs | ts]), do: for(h <- hs, t <- selections(ts), do: [h | t])

  @doc """
  Reduce over selections from a List of lists (LoL).

  If the list is empty, there are no invocations of the reducer,
  and the result is just the initial value.

  The reducer is invoked for each full selection.
  The reducer may throw a final result for prompt return
  (`reduce_while` semantics but using throw/rescue).
  """
  @spec reduce_selects(list(), a, E.terminator!(list(), a)) :: a
        when a: var
  def reduce_selects([hs | ts], init, redr) when is_terminator(redr) do
    Enum.reduce(hs, init, fn h, acc ->
      Enum.reduce(selections(ts), acc, fn t, acc -> redr.([h | t], acc) end)
    end)
  end

  @doc """
  Find a selection and return promptly if a target is found.

  The terminator function should throw `{:return, result`} on successful match.

  Return either:
  - `{:ok, result}` the prompt result value thrown by the terminator function
  - `{:no_match, final_accumulator}` if the search completed unsuccessfully
  """
  @spec find_selection(list(), a, E.terminator!(list(), a)) ::
          {:ok, any()} | {:no_match, a}
        when a: var
  def find_selection(ls, init, terminate!) when is_list(ls) and is_terminator(terminate!) do
    {:no_match, reduce_selects(ls, init, terminate!)}
  catch
    {:return, result} -> {:ok, result}
  end

  @doc """
  Number of permutations of k elements taken from a collection of size n.

  The ordering of the k elements is significant (list semantics).

  The formula is: `nPk = n! / (n-k)!`

  If `k == 0` the result is `1`.

  If `k == n` the result is `n!`.

  If `k > n` the result is `0`.

  ## Examples
      iex> nperms(5,3)
      60
      iex> nperms(5,0)
      1
      iex> nperms(5,5)
      120
      iex> nperms(5,10)
      0
  """
  @spec nperms(non_neg_integer(), non_neg_integer()) :: pos_integer()
  def nperms(n, k) when is_int_nonneg(n) and is_int_nonneg(k) do
    Exa.Math.fac(n, k)
  end

  @doc """
  Get all permutations of k elements taken from a list of length n.

  The ordering of the k elements is significant (list semantics).

  ## Examples

      iex> permutations([1,2,3], 2)
      [[1,2], [2,1], [1,3], [3,1], [2,3], [3,2]]

      iex> permutations([1,2,3,4], 0)
      [[]]

      iex> permutations([1,2,3,4], 5)
      []
  """
  @spec permutations(list(), non_neg_integer()) :: [list()]

  def permutations(_ls, 0), do: [[]]

  def permutations(ls, k) when is_int_nonneg(k) and k <= length(ls) do
    Enum.reduce(combinations(ls, k), [], fn c, ps -> ps ++ permutations(c) end)
  end

  def permutations(_ls, _k), do: []

  @doc """
  Binomial coefficient: 
  the number of combinations of k elements taken from a collection of size n.

  For a combination, the ordering of the k elements does not matter (set semantics).

  The formula is: `nCk = n! / k! (n-k)!`

  If `k == 0` or `k == n` the result is `1`.

  If `k > n` the result is `0`.

  ## Examples
      iex> ncombs(5,3)
      10
      iex> ncombs(5,5)
      1
      iex> ncombs(5,0)
      1
      iex> ncombs(5,10)
      0
  """
  @spec ncombs(non_neg_integer(), non_neg_integer()) :: pos_integer()

  def ncombs(n, k) when is_int_nonneg(n) and is_int_nonneg(k) and k <= n do
    div(Exa.Math.fac(n, k), Exa.Math.fac(k))
  end

  def ncombs(n, k) when is_int_nonneg(n) and is_int_nonneg(k) and k > n, do: 0

  @doc """
  Get all combinations of k elements taken from a list of length n.

  The ordering of the k elements does not matter (set semantics).

  ## Examples

      iex> combinations([1,2,3,4], 2)
      [[1,2], [1,3], [1,4], [2,3], [2,4], [3,4]]

      iex> combinations([1,2,3,4], 0)
      [[]]

      iex> combinations([1,2,3,4], 5)
      []
  """
  @spec combinations(list(), non_neg_integer()) :: [list()]

  def combinations(_ls, 0), do: [[]]

  def combinations([h | ts] = ls, k) when is_int_nonneg(k) and k <= length(ls) do
    Enum.map(combinations(ts, k - 1), &[h | &1]) ++ combinations(ts, k)
  end

  def combinations(_ls, _k), do: []
end

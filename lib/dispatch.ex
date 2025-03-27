defmodule Exa.Dispatch do
  @moduledoc """
  A dispatcher for tagged tuples.

  The dispatcher is like a _protocol_ for tagged tuples.

  ## Tagged Tuples

  A tagged tuple is a tuple whose first element is an atom
  that specifies the semantic meaning of the data
  and the types of the remaining elements.

  Tagged tuples are a standard data structure for Erlang,
  but can also be convenient and efficient for Elixir. 
  Tagged tuples work best with a small number of elements
  that can be easily constructed and pattern matched.

  As the complexity increases, it is better to migrate to _structs,_
  which have the existing _protocol_ mechanism for dispatching 
  to implementations.

  ## Dispatch Pattern

  The pattern calls for several components:
  - _behaviour_ that defines an abstract API 
  - two or more implementations comprising:
    - tagged tuple (tag, tuple type and a guard)
    - module that implements the behaviour 
  - dispatch map associating each tag with a module
  - union type defined to be one of the tags or tagged tuples
    that is used for the API behaviour signatures
  - library interface module that implements the behaviour
    and dispatches calls to a specific module using the _dispatcher_

  The different tagged tuples do not necessarily have to be the same size.

  ## Dispatching

  There are three cases for dispatching:
  - Constructors that build a new tagged tuple instance:
    dispatch on an explicit tag; no tuple argument; tuple return type.
  - Functions of an existing tagged tuple instance:
    dispatch on the first element of the tuple; pass tuple argument.
  - Functions with separate tag _and_ untagged data:
    dispatch on tag; pass data as just another argument.

  The use case for untagged data, is when there's a 
  list of untagged data items, 
  and one tag applies to the whole collection.
  Not putting the tag in every tuple saves space for long lists
  (e.g. colors, spatial points).

  Note that the _untagged data_ can be any datatype, not just a tuple. 
  The argument is not type checked. 
  For example, some implementations might pass a single value,
  rather than a singleton tuple, to save space and time
  (e.g. RGB color is a 3-tuple, but GRAY color is just a byte value,
  not a tuple with one byte element).

  ## See Also

  See the guards:
  - `Exa.Types.is_tuple_tag/2` for variable length tagged tuple
  - `Exa.Types.is_tuple_tag/3` for fixed length tagged tuple

  ## Extended Example

  ```
  \# tagged tuple types
  @type foo1() :: {:f1, ...}
  @type foo2() :: {:f2, ...}

  \# union abstract types
  @type tags() :: :f1 | :f2
  @type foo() :: foo1() | foo2()

  \# behaviour
  defmodule Foo do
    \# constant dispatcher map
    @disp %{:f1 => Foo1, :f2 => Foo2}

    \# abstract API
    @callback new(tags(), String.t()) :: foo()
    def new(tag, name), do: Exa.Dispatch.dispatch(tag,:new,[name])
    @callback bar(foo(), integer()) :: foo()
    def bar(f, i), do: Exa.Dispatch.dispatch(@disp,f,[i])
  end

  \# implementations

  defmodule Foo1 do
    @behaviour Foo
    @impl true
    def new(:f1, name), do: ... {:f1, name, ...}
    @impl true 
    def bar(f1, i), do: ... update_f1
  end

  defmodule Foo2 do
    @behaviour Foo
    @impl true
    def new(:f2, name), do: ... {:f2, name, ...}
    @impl true 
    def bar(f2, i), do: ... update_f2
  end
  ```
  """
  require Logger

  # -----
  # types
  # -----

  @type tag() :: atom()
  @type fun_name() :: atom()
  @type tag_tuple() :: tuple()
  @type args() :: list()

  @type dispatcher() :: %{tag() => module()}

  # ----------
  # dispatcher
  # ----------

  # return type is generic, so cannot use dialyzer

  @doc "Dispatch tagged tuple."
  @spec dispatch(dispatcher(), tag() | tag_tuple(), fun_name(), args()) :: any()
  def dispatch(dispatcher, tag_or_tuple, fun_name, args \\ [])

  def dispatch(disp, tag, fun, args)
      when is_map(disp) and is_atom(tag) and
             is_atom(fun) and is_list(args) and is_map_key(disp, tag) do
    # dispatch based on a tag to determine result type
    disp |> Map.fetch!(tag) |> apply(fun, [tag | args])
  end

  def dispatch(disp, tup, fun, args)
      when is_map(disp) and is_tuple(tup) and
             is_atom(fun) and is_list(args) and is_map_key(disp, elem(tup, 0)) do
    # dispatch based on an existing tuple
    disp |> Map.fetch!(elem(tup, 0)) |> apply(fun, [tup | args])
  end

  def dispatch(disp, tag_or_tup, _, _)
      when is_map(disp) and
             (is_atom(tag_or_tup) or is_tuple(tag_or_tup)) do
              IO.inspect(disp)
              IO.inspect(tag_or_tup)
    tag = if is_tuple(tag_or_tup), do: elem(tag_or_tup, 0), else: tag_or_tup
    msg = "Failed dispatch: tag '#{tag}' not key in #{inspect(disp)}"
    Logger.error(msg)
    raise ArgumentError, message: msg
  end
end

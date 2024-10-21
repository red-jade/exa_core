defmodule Exa.Process do
  @moduledoc """
  Utilities to register and find processes in a namespace.
  A namespace is a sequence of names (strings, atoms).

  Local map and reduce with timeout.
  No processes are spawned.
  All executions are within the current (self) process.
  If you want parallel map and reduce, see `Exa.Exec`.
  """
  use Exa.Constants
  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Fun
  alias Exa.Fun, as: F

  # -----
  # types
  # -----

  @typedoc "The combined key for a namespace."
  @type nskey() :: atom()

  @typedoc "Segment of a namespace."
  @type nsseg() :: String.t() | atom()
  defguard is_nsseg(s) when is_string_nonempty(s) or is_atom(s)

  @typedoc "A namespace is a sequence of segments."
  @type ns() :: [nsseg(), ...]
  defguard is_ns(ns) when is_list(ns) and is_nsseg(hd(ns))

  # ----------------
  # public functions
  # ---------------- 

  @doc "Get integer from self pid."
  @spec ipid() :: pos_integer()
  def ipid(), do: ipid(self())

  @doc "Get integer from pid."
  @spec ipid(pid) :: pos_integer()
  def ipid(pid) when is_pid(pid) do
    "#{inspect(pid)}" |> String.split(".") |> Enum.at(1) |> String.to_integer()
  end

  @doc "Get the messages waiting in the inbox."
  @spec msg_box() :: list()
  def msg_box(), do: self() |> Process.info(:messages) |> elem(1)

  @doc "Get the number of messages waiting in the inbox."
  @spec msg_box_len() :: E.count()
  def msg_box_len(), do: self() |> Process.info(:message_queue_len) |> elem(1)

  @doc "Get the memory size of the process."
  @spec mem_sz() :: E.bsize()
  def mem_sz(), do: self() |> Process.info(:memory) |> elem(1)

  @doc """
  Get a value from the process dictionary.
  If it is not set, run a function to populate the value.
  """
  @spec get_or_set(any(), (-> any())) :: any()
  def get_or_set(key, fun) when is_function(fun, 0) do
    case Process.get(key) do
      nil ->
        init = fun.()
        nil = Process.put(key, init)
        init

      value ->
        value
    end
  end

  @doc """
  Delete an entry from the process dictionary.

  See `Process.delete/1`.
  """
  @spec delete(any()) :: nil | any()
  def delete(key), do: Process.delete(key)

  @doc "Register a process in a namespace."
  @spec register!(ns(), nsseg(), pid()) :: nskey()
  def register!(ns, name, pid) do
    key = key(ns, name)
    Process.register(pid, key)
    key
  end

  @doc """
  Look-up a process. 
  Raise an error if the process is not registered.
  """
  @spec whereis!(ns(), nsseg()) :: pid()
  def whereis!(ns, name) do
    key = key(ns, name)

    case Process.whereis(key) do
      nil -> raise ArgumentError, message: "Process '#{key}' not registered"
      pid -> pid
    end
  end

  @doc """
  Unregister a process in a namespace.
  Raise an error if the process is not registered.
  """
  @spec unregister!(ns(), nsseg()) :: nskey()
  def unregister!(ns, name) do
    key = key(ns, name)
    Process.unregister(key)
    key
  end

  @doc "Get the key for a namespace."
  @spec key(ns()) :: nskey()
  def key(ns) when is_ns(ns), do: ns |> Enum.join("_") |> String.to_atom()

  # --------------------------------
  # useful single process interrupts
  # --------------------------------

  @typep timer() :: {timer :: :timer.tref(), event :: {:interrupt, reference()}}

  @doc """
  Map with a finite timeout (ms).

  No new processes is spawned. 
  The call is blocking. All computation happens in this _self_ process.
  (so not the same as `Task.asynch` + `Task.await`).

  The implementation configures an interrupt for itself (`:timer.send_after/2`),
  then interleaves computation steps
  with a zero-wait test to receive the interrupt (`receive after 0`).
  """
  @spec tmap(Enumerable.t(a), E.mapper(a, b), E.timeout1()) :: E.tresult([b]) when a: var, b: var
  def tmap(ls, mapr, dt \\ @max_duration) when is_mapper(mapr) and is_timeout1(dt) do
    do_tmap(ls, Fun.safe(mapr), start_timer(dt), [])
  end

  @spec do_tmap(Enumerable.t(a), F.safe_mapper(a, b), timer(), [b]) :: [b] | {:timeout, [b]}
        when a: var, b: var
  defp do_tmap(ls, mapr, {_, interrupt} = timer, out) do
    receive do
      ^interrupt -> {:timeout, Enum.reverse(out)}
    after
      0 ->
        case Enum.split(ls, 1) do
          {[], []} ->
            stop_timer({:ok, Enum.reverse(out)}, timer)

          {[h], t} ->
            case mapr.([h]) do
              {:error, _} = err -> stop_timer(err, timer)
              {:ok, val} -> do_tmap(t, mapr, timer, [val | out])
            end
        end
    end
  end

  @doc """
  Reduce with a finite timeout (ms).

  No new processes is spawned. 
  The call is blocking. All computation happens in this _self_ process.
  (so not the same as `Exa.Exec` or `Task.asynch` + `Task.await`).

  The implementation configures an interrupt for itself (`:timer.send_after/2`),
  then interleaves computation steps
  with a zero-wait test to receive the interrupt (`receive after 0`).
  """
  @spec treduce(Enumerable.t(a), acc, E.reducer(a, acc), E.timeout1()) :: E.tresult(acc)
        when a: var, acc: var
  def treduce(ls, init, redr, dt \\ @max_duration) when is_reducer(redr) and is_timeout1(dt) do
    do_treduce(ls, init, Fun.safe(redr), start_timer(dt))
  end

  @spec do_treduce(Enumerable.t(), acc, F.safe_reducer(acc), timer()) ::
          acc | {:timeout, acc}
        when a: var, acc: var
  defp do_treduce(ls, acc, redr, {_, interrupt} = timer) do
    receive do
      ^interrupt -> {:timeout, acc}
    after
      0 ->
        case Enum.split(ls, 1) do
          {[], []} ->
            stop_timer({:ok, acc}, timer)

          {[h], t} ->
            case redr.([h, acc]) do
              {:error, _} = err -> stop_timer(err, timer)
              {:ok, new_acc} -> do_treduce(t, new_acc, redr, timer)
            end
        end
    end
  end

  @doc """
  Reduce while with a finite timeout (ms).

  No new processes is spawned. 
  The call is blocking. All computation happens in this _self_ process.
  (so not the same as `Task.asynch` + `Task.await`).

  The implementation configures an interrupt for itself (`:timer.send_after/2`),
  then interleaves computation steps
  with a zero-wait test to receive the interrupt (`receive after 0`).

  The continue/halt semantics are the same as `Enum.reduce_while/3`.
  """
  @spec treduce_while(Enumerable.t(a), acc, E.while_reducer(a, acc), E.timeout1()) ::
          E.tresult(acc)
        when a: var, acc: var
  def treduce_while(ls, init, redr, dt \\ @max_duration)
      when is_whiler(redr) and is_timeout1(dt) do
    do_treduce_while(ls, init, Fun.safe(redr), start_timer(dt))
  end

  @spec do_treduce_while(Enumerable.t(), acc, F.safe_reducer(acc), timer()) :: E.tresult(acc)
        when a: var, acc: var
  defp do_treduce_while(ls, acc, redr, {_, interrupt} = timer) do
    receive do
      ^interrupt -> {:timeout, acc}
    after
      0 ->
        case Enum.split(ls, 1) do
          {[], []} ->
            stop_timer({:ok, acc}, timer)

          {[h], t} ->
            case redr.([h, acc]) do
              {:error, _} = err -> stop_timer(err, timer)
              {:ok, {:halt, new_acc}} -> stop_timer({:ok, new_acc}, timer)
              {:ok, {:cont, new_acc}} -> do_treduce_while(t, new_acc, redr, timer)
            end
        end
    end
  end

  # -----------------
  # private functions
  # -----------------

  # start a self-interrupting timer
  @spec start_timer(E.duration_millis()) :: timer()
  defp start_timer(dt) do
    interrupt = {:interrupt, make_ref()}
    {:ok, tref} = dt |> min(@max_duration) |> :timer.send_after(interrupt)
    {tref, interrupt}
  end

  # stop a self-interrupting timer
  # and delete any pending interrupt messages
  @spec stop_timer(t, timer()) :: t when t: var
  defp stop_timer(result, {tref, interrupt}) do
    :timer.cancel(tref)
    Exa.Message.purge(interrupt)
    result
  end

  @spec key(ns(), nsseg()) :: nskey()
  def key(ns, name) when is_ns(ns) and is_nsseg(name), do: key(ns ++ [name])
end

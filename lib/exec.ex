defmodule Exa.Exec do
  @moduledoc """
  Lightweight asynchronous function execution with timeout.

  The pattern can be oneshot, map or map-reduce.

  There is simple capture of timeout and errors.
  For anything more complex, use `Task` and `GenServer`.

  The computation should be significant to offset the overheads
  for spawning processes, receiving results and purging dead messages.

  The cleanup adds time beyond the timeout limit,
  so the total elapsed time will be greater than the timeout itself.
  """
  use Exa.Constants
  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Fun
  alias Exa.Fun, as: F

  alias Exa.Stopwatch

  # ----------------
  # public functions
  # ---------------- 

  @doc """
  Apply a function to an enumerable in parallel.

  The timeout is applied for each individual computation.
  So the maximum elapsed time will be the timeout
  multiplied by the length of the enumerable.
  """
  @spec pmap(Enumerable.t(a), E.mapper(a, b), E.timeout1()) :: E.tresult([b])
        when a: var, b: var
  def pmap(vec, mapr, timeout \\ @max_duration) do
    pmap_reduce(vec, [], mapr, fn x, acc -> [x | acc] end, timeout)
  end

  @doc """
  Apply a function to an enumerable in parallel,
  then reduce over the results.

  The mapper runs in parallel in spawned processes.
  The reducer runs in this process, as results become available.

  The timeout is applied for each individual computation.
  So the maximum elapsed time will be the timeout
  multiplied by the length of the enumerable.
  """
  @spec pmap_reduce(Enumerable.t(a), acc, E.mapper(a, b), E.reducer(b, acc), E.timeout1()) ::
          E.tresult(acc)
        when a: var, b: var, acc: var
  def pmap_reduce(vec, init, mapr, redr, timeout \\ @max_duration)
      when is_mapper(mapr) and is_reducer(redr) and is_timeout1(timeout) do
    vec
    |> execs(Fun.safe(mapr))
    |> recvs({:ok, init}, Fun.safe(redr), Stopwatch.start(), timeout)
  end

  @doc """
  Apply a function to an Enumerable in parallel,
  then reduce over the results.

  The initial value for the reduction is the first element of the mapped list.

  The mapper runs in parallel in spawned processes.
  The reducer runs in this process, as results become available.

  The timeout is applied for each individual computation.
  So the maximum elapsed time will be the timeout
  multiplied by the length of the enumerable.
  """
  @spec pmap_chain(Enumerable.t(a), E.mapper(a, b), E.reducer(b, acc), E.timeout1()) ::
          E.tresult(acc)
        when a: var, b: var, acc: var
  def pmap_chain(vec, mapr, redr, timeout \\ @max_duration)
      when is_list(vec) and is_mapper(mapr) and is_reducer(redr) and is_timeout1(timeout) do
    start = Stopwatch.start()
    [exec1 | execs] = execs(vec, Fun.safe(mapr))
    init = recv(exec1, timeout)
    elapsed = Stopwatch.elapsed_ms(start)
    recvs(execs, init, Fun.safe(redr), start, timeout - elapsed)
  end

  @doc """
  Execute a single function asynchronously in a new process.

  Return the new PID and unique response reference. 

  Receive the result with `recv/2`.

  Similar to `Task.async/1`.
  """
  @spec exec(fun(), list()) :: E.pidref()
  def exec(fun, args) when is_function(fun) and is_list(args) do
    do_exec(make_ref(), Fun.safe(fun), args)
  end

  @spec do_exec(reference(), fun(), list()) :: E.pidref()
  defp do_exec(ref, safe_fun, args)
       when is_ref(ref) and is_function(safe_fun) and is_list(args) do
    self = self()
    pid = spawn(fn -> send(self, {self(), ref, safe_fun.(args)}) end)
    {pid, ref}
  end

  @doc """
  Receive the result from an executed function.

  The timeout is a finite timeout (ms).

  Similar to `Task.await/2`.
  """
  @spec recv(E.match(), E.timeout1()) :: E.tresult(any())
  def recv(match, timeout \\ @max_duration) when is_timeout1(timeout) do
    receive do
      # TODO - tup when is_match(tup, match) -> 
      tup when is_message(tup) and is_match_prf(match, tup) -> elem(tup, 2)
    after
      timeout ->
        kill(match)
        {:timeout, nil}
    end
  end

  @doc """
  Kill spawned process(es) and 
  remove all their messages from the message queue.

  The argument can be a single pid or a  
  single exec ref (pid & reference),
  a list of these, or map with these as values.


  There is a race condition if kill signal is delayed,
  so there could still be dead messages delivered to the inbox
  after this function completes.
  """
  @spec kill(pid() | E.pidref() | [pid() | E.pidref()] | %{any() => pid() | E.pidref()}) :: :ok

  def kill(pid) when is_pid(pid) do
    Process.exit(pid, :kill)
    Exa.Message.purge(pid)
  end

  def kill({pid, _ref} = pidref) when is_pidref(pidref) do
    Process.exit(pid, :kill)
    Exa.Message.purge(pidref)
  end

  def kill(prfs) when is_list(prfs), do: Enum.each(prfs, fn prf -> kill(prf) end)

  def kill(prfs) when is_map(prfs), do: Enum.each(prfs, fn {_, prf} -> kill(prf) end)

  @doc """
  Kill a list of processes and purge all messages for a reference.
  """
  @spec kill([pid() | E.pidref()], reference()) :: :ok
  def kill(pids, ref) when is_list(pids) and is_ref(ref) do
    # race condition here if kill signal is delayed
    # so could still be dead messages in the queue
    Enum.each(pids, fn
      {pid, _} -> Process.exit(pid, :kill)
      pid -> Process.exit(pid, :kill)
    end)

    Exa.Message.purge(ref)
  end

  # -----------------
  # private functions
  # -----------------

  # spawn mapper processes over an enumerable of data
  @spec execs(Enumerable.t(a), F.safe_mapper(a, any())) :: [E.pidref()] when a: var
  defp execs(vec, mapr) do
    # use the same ref for all processes
    ref = make_ref()

    vec
    |> Enum.reduce([], fn d, execs -> [do_exec(ref, mapr, [d]) | execs] end)
    |> Enum.reverse()
  end

  # gather results from mapper processes and merge a result
  # similar to Task.await_many/2
  @spec recvs([E.pidref()], E.tresult(acc), F.safe_reducer(acc), E.time_micros(), E.timeout1()) ::
          E.tresult(acc)
        when acc: var

  defp recvs([exec | execs], {:ok, acc}, redr, start, timeout) do
    # must accumulate µs from overall start
    # to avoid round to zero for execs < 1 ms
    dt = timeout - Stopwatch.elapsed_ms(start)

    result =
      if dt < 1 do
        kill(exec)
        {:timeout, acc}
      else
        case recv(exec, dt) do
          {:ok, ans} ->
            case redr.([ans, acc]) do
              {:error, _} = err ->
                err

              {:ok, new_acc} = ok ->
                elapsed = Stopwatch.elapsed_ms(start)
                if elapsed >= timeout, do: {:timeout, new_acc}, else: ok
            end

          {:error, _} = err ->
            err

          {:timeout, nil} ->
            {:timeout, acc}
        end
      end

    recvs(execs, result, redr, start, timeout)
  end

  defp recvs([], acc, _, _, _), do: acc

  defp recvs([{_pid, ref} | _] = execs, timeout_err, _, _, _) do
    # all processes use the same ref
    # makes puring the message queue much faster
    kill(execs, ref)
    timeout_err
  end
end

defmodule Exa.Stopwatch do
  @moduledoc """
  A timer for elapsed time and function execution.
  The times are for use in the current runtime session,
  not necessarily valid for storing and restarting.

  Based on `:erlang.monotonic_time(:microsecond)`.

  The stopwatch will never give a negative time, but it may give 0. 

  The resolution will never be better than µs, but it could be lower.
  For example, an OS with a milisecond clock will have 1000 µs increments.

  Accuracy and precision depends on the OS.

  The output may depend on schedulers and pausing of processes.
  The best range of use is for greater than 10s in the current session.
  """

  import Exa.Types
  alias Exa.Types, as: E

  # types

  @type average_duration() :: {float(), :milliseconds}

  # memory in bytes
  @type size_b() :: non_neg_integer()
  @type average_size() :: float()
  @type delta_size() :: float()

  @type metrics() :: {
          average_duration(),
          delta_ets :: delta_size(),
          delta_mem :: delta_size(),
          result_size :: size_b(),
          result_debug_size :: size_b()
        }

  # ----------------
  # public functions
  # ----------------

  @doc """
  Get the current `now` time value in microseconds.

  Note that since Erlang OTP 26,
  this value can be negative.
  """
  @spec now() :: E.time_micros()
  def now(), do: :erlang.monotonic_time(:microsecond)

  @doc """
  Get the start time at current `now` time.

  Note that since Erlang OTP 26,
  this value can be negative.
  """
  @spec start() :: E.time_micros()
  def start(), do: now()

  @doc """
  Get the elapsed time since a previous call to `now()`.
  The value maybe zero.
  """
  @spec elapsed(E.time_micros()) :: E.duration_micros()
  def elapsed(start), do: now() - start

  @doc """
  Get the average elapsed time to execute a function
  a number of times (default 1).
  There is a small overhead when n > 1.

  The return value is the result of the _first_ execution.

  Also get other system metrics: 
  - net change in ETS storage (bytes), not averaged
  - net change in process memory (bytes), not averaged
  - raw size of the single last result (bytes)
  - debug size of the single last result (bytes)

  The function will run many system calls,
  coordinate schedulers for the monotonic time,
  and run the garbage collector - twice.

  So only use for testing, not at runtime.

  For more sophisticated benchmarking, use Benchee.
  """
  @spec execute((-> any()), E.count1()) :: {any(), metrics()}
  def execute(fun, n \\ 1) when is_function(fun, 0) and is_count1(n) do
    :erlang.garbage_collect()
    ets = :erlang.memory(:ets)
    mem = :erlang.memory(:processes)
    start = start()
    [result | _] = Enum.map(1..n, fn _ -> fun.() end)
    elapsed = elapsed(start)
    :erlang.garbage_collect()
    delta_ets = :erlang.memory(:ets) - ets
    delta_mem = :erlang.memory(:processes) - mem
    size = :erts_debug.size(result)
    debug_size = :erts_debug.flat_size(result)
    {result, {{elapsed / n, :microsecond}, delta_ets / n, delta_mem / n, size, debug_size}}
  end
end

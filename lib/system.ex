defmodule Exa.System do
  @moduledoc "Utilities for System parameters."

  @doc """
  Get the number of logical processors on the node.
  Logical processors means the number of hardware threads reported by the cpu.
  It is often 2 x the number of cores on Intal chips.

  The number of logical processors is also the default 
  number of schedulers started by the BEAM runtime,
  based on one-scheduler-per-processor heuristic.

  The number of logical processors can be used in deciding
  the number of processes to use for data-parallel concurrency.
  """
  @spec n_processors() :: pos_integer()
  def n_processors(), do: :erlang.system_info(:logical_processors)
end

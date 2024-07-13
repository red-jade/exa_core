defmodule Exa.System do
  @moduledoc "Utilities for System parameters."
  require Logger
  import Exa.Types
  alias Exa.Types, as: E

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

  @doc "Get an installed executable path."
  @spec installed(atom() | String.t()) :: nil | E.filename()
  def installed(exe) when is_atom(exe) or is_string(exe) do
    exe |> to_string() |> System.find_executable()
  end

  @doc """
  Ensure a target executable is installed and accessible 
  on the OS command line (PATH), otherwise raise an error.
  """
  @spec ensure_installed!(atom() | String.t()) :: E.filename()
  def ensure_installed!(exe) when is_atom(exe) or is_string(exe) do
    case installed(exe) do
      nil ->
        msg = "Cannot find '#{exe}' executable"
        Logger.error(msg)
        raise RuntimeError, message: msg

      exe ->
        exe
    end
  end
end

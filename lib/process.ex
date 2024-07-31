defmodule Exa.Process do
  @moduledoc """
  Utilities to register and find processes in a namespace.

  A namespace is a sequence of names (strings, atoms).
  """

  import Exa.Types
  alias Exa.Types, as: E

  # -----
  # types
  # -----

  @typedoc "The combined key for a namespace."
  @type nskey() :: atom()

  @typedoc "Segment of a namespace."
  @type nsseg() :: String.t() | atom()
  defguard is_nsseg(s) when is_nonempty_string(s) or is_atom(s)

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

  # -----------------
  # private functions
  # -----------------

  @spec key(ns(), nsseg()) :: nskey()
  def key(ns, name) when is_ns(ns) and is_nsseg(name), do: key(ns ++ [name])
end

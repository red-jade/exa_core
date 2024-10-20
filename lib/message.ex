defmodule Exa.Message do
  @moduledoc "Message utilities."

  import Exa.Types
  alias Exa.Types, as: E

  # ---------
  # constants
  # ---------

  # default timeout
  @timeout 50

  # -----
  # types
  # -----

  # any generic message or payload
  @typep msg() :: any()

  # ----------------
  # public functions
  # ----------------

  @doc """
  Send a message to a process. 
  Returns the message.

  Just an alias for `Kernel.send/2`.
  """
  @spec cast(pid(), t) :: t when t: var
  def cast(pid, msg) when is_pid(pid), do: send(pid, msg)

  @doc """
  Send a payload to a process. 

  The message will be a 3-tuple consisting of:
  - sender PID (self)
  - generated reference 
  - payload

  Returns the reference.
  """
  @spec cast_ref(pid(), msg()) :: reference()
  def cast_ref(pid, payload) when is_pid(pid) do
    ref = make_ref()
    send(pid, {self(), ref, payload})
    ref
  end

  @doc """
  Send a message to many processes.
  The processes can be an explicit list 
  or a map with processes for values.

  The list or map argument may be empty.
  """

  @spec multicast([pid()] | %{any() => pid()}, msg()) :: :ok

  def multicast(pids, msg) when is_list(pids) do
    Enum.each(pids, fn pid -> send(pid, msg) end)
  end

  def multicast(map, msg) when is_map(map) do
    Enum.each(map, fn {_, pid} -> send(pid, msg) end)
  end

  @doc """
  Send a payload to many processes.

  The messages will be 3-tuples consisting of:
  - sender PID (self)
  - generated Reference 
  - payload

  The processes can be an explicit list 
  or a map with processes for values.
  The list or map argument may be empty.

  Return a map of References to PIDs for the messages.
  """

  @spec multicast_ref([pid()] | %{any() => pid()}, msg()) :: %{pid() => reference()}

  def multicast_ref(pids, payload) when is_list(pids) do
    Enum.reduce(pids, %{}, fn pid, prs ->
      Map.put(prs, pid, cast_ref(pid, payload))
    end)
  end

  def multicast_ref(pids, payload) when is_map(pids) do
    Enum.reduce(pids, %{}, fn {_, pid}, prs ->
      Map.put(prs, pid, cast_ref(pid, payload))
    end)
  end

  @doc """
  Send blocking request RPC, with a finite timeout (ms).

  The destination must have a receive clause:
  ```
  receive do
    ...
    {from, ref, request} when is_pid(from) and is_reference(ref) ->
       response = ...handle request message...
       Message.response(from, ref, response)
       ...
    ...
  end
  ```

  Only use when you absolutely positively must have synchronization.
  """
  @spec request(pid(), t, E.timeout1()) :: {:ok, t} | :timeout when t: var
  def request(to, request, timeout \\ @timeout) when is_pid(to) do
    to |> cast_ref(request) |> wait(timeout)
  end

  @doc "Reply to an RPC request."
  @spec response(pid(), reference(), t) :: E.message(t) when t: var
  def response(from, ref, response) when is_pid(from) and is_ref(ref) do
    send(from, {self(), ref, response})
  end

  @doc """
  Remove *all* messages from the message queue. 

  Optionally supply a label and print all the messages.

  Should only be used for testing and debugging.
  """
  @spec drain(E.maybe(String.t())) :: :ok
  def drain(label \\ nil) do
    receive do
      msg ->
        if not is_nil(label), do: IO.inspect(msg, label: label)
        drain(label)
    after
      0 -> :ok
    end
  end

  @doc """
  Purge the message queue of all matching messages.

  There are four possibilities for the match, depending on the argument type:
  pid, ref, pidref, or constant (see `match()` type).
  """
  @spec purge(E.match() | any()) :: :ok
  def purge(pid) when is_pid(pid), do: purge_pid(pid)
  def purge(ref) when is_ref(ref), do: purge_ref(ref)
  def purge({pid, ref} = pidref) when is_pidref(pidref), do: purge_pidref(pid, ref)
  def purge(const), do: purge_const(const)

  defp purge_pid(pid) do
    receive do
      {^pid, _, _} -> purge_pid(pid)
    after
      0 -> :ok
    end
  end

  defp purge_ref(ref) do
    receive do
      {_, ^ref, _} -> purge_ref(ref)
    after
      0 -> :ok
    end
  end

  defp purge_pidref(pid, ref) do
    receive do
      {^pid, ^ref, _} -> purge_pidref(pid, ref)
    after
      0 -> :ok
    end
  end

  defp purge_const(const) do
    receive do
      ^const -> purge_const(const)
    after
      0 -> :ok
    end
  end

  @doc """
  Wait for a specific matching message, or timeout.

  There are four possibilities for the match, depending on the argument type:
  pid, ref, pidref, or constant signal (see `match()` type).

  For PID, ref and pidref, return the payload (2nd element of the tuple),
  otherwise return the constant message.
  """
  @spec wait(E.match() | msg(), E.timeout1()) :: {:ok, msg()} | :timeout
  def wait(match, timeout \\ @timeout)

  def wait(pid, timeout) when is_pid(pid) and is_timeout1(timeout),
    do: wait_pid(pid, timeout)

  def wait(ref, timeout) when is_ref(ref) and is_timeout1(timeout),
    do: wait_ref(ref, timeout)

  def wait({pid, ref} = pidref, timeout) when is_pidref(pidref) and is_timeout1(timeout),
    do: wait_pidref(pid, ref, timeout)

  def wait(const, timeout) when is_timeout1(timeout),
    do: wait_const(const, timeout)

  defp wait_pid(pid, timeout) do
    receive do
      {^pid, _, payload} -> {:ok, payload}
    after
      timeout -> :timeout
    end
  end

  defp wait_ref(ref, timeout) do
    receive do
      {_, ^ref, payload} -> {:ok, payload}
    after
      timeout -> :timeout
    end
  end

  defp wait_pidref(pid, ref, timeout) do
    receive do
      {^pid, ^ref, payload} -> {:ok, payload}
    after
      timeout -> :timeout
    end
  end

  defp wait_const(const, timeout) do
    receive do
      ^const -> {:ok, const}
    after
      timeout -> :timeout
    end
  end

  @doc """
  Wait for a specific matching message, or raise error on timeout.

  There are three possibilities for the match, depending on the argument type:
  PID, ref or constant (see `match()` type).
  """
  @spec wait!(E.match() | msg(), E.timeout1()) :: msg()
  def wait!(match, timeout \\ @timeout) do
    case wait(match, timeout) do
      :timeout -> raise RuntimeError, message: "Wait timeout for '#{inspect(match)}'"
      {:ok, payload} -> payload
    end
  end
end

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

  @typedoc "Any message."
  @type msg() :: any()

  # ----------------
  # public functions
  # ----------------

  @doc """
  Send a message to a process. 
  Returns the message.
  Just an alias for `Kernel.send/2`.
  """
  @spec cast(pid(), msg()) :: any()
  def cast(pid, msg) when is_pid(pid), do: send(pid, msg)

  @doc """
  Send a message to many processes.
  The processes can be an explicit list 
  or map with processes for values.

  The list or map argument may be empty.
  """

  @spec multicast([pid()] | %{any() => pid()}, msg()) :: :ok

  def multicast(pids, msg) when is_list(pids), do: Enum.each(pids, &send(&1, msg))

  def multicast(map, msg) when is_map(map) do
    Enum.each(map, fn {_, pid} when is_pid(pid) -> send(pid, msg) end)
  end

  @doc """
  Send blocking request RPC. 

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
  Only use when you absolutely must have synchronization.
  """
  @spec request(pid(), msg(), E.timeout1()) :: msg() | :timeout
  def request(to, request, timeout \\ @timeout) when is_pid(to) do
    ref = make_ref()
    send(to, {self(), ref, request})

    receive do
      {^ref, response} -> response
    after
      timeout -> :timeout
    end
  end

  @doc "Reply to an RPC request."
  @spec response(pid(), reference(), msg()) :: msg()
  def response(from, ref, response) when is_pid(from) and is_reference(ref) do
    send(from, {ref, response})
  end

  @doc """
  Drain the message queue. 
  Optionally supply a label and print all the messages.
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

  @doc "Wait for a specific event, or timeout."
  @spec wait(any(), E.timeout1()) :: :ok | :timeout
  def wait(event, timeout \\ @timeout) when is_timeout1(timeout) do
    receive do
      ^event -> :ok
    after
      timeout -> :timeout
    end
  end

  @doc "Wait for a specific event, or raise error on timeout."
  @spec wait!(any(), E.timeout1()) :: nil
  def wait!(event, timeout \\ @timeout) when is_timeout1(timeout) do
    if wait(event, timeout) == :timeout do
      raise RuntimeError, message: "Wait timeout for '#{inspect(event)}'"
    end
  end
end

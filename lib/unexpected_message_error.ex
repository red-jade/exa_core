defmodule Exa.UnexpectedMessageError do
  @moduledoc """
  An error to be raised when a `receive` statement 
  gets an unmatched message.

  ## Example

  ```
    receive do
      {pid, ref, payload} when is_pid(pid) and is_ref(ref) -> 
         ... process payload ...
      msg -> 
         raise Exa.UnexpectedMessageException, event: msg
    end
  ```
  """

  defexception [:event]

  def message(e) do
    "Unexpected message: #{inspect(e.event)}"
  end
end

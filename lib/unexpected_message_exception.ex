defmodule UnexpectedMessageException do
  defexception [:event]

  def message(e) do
    "Unexpected message: #{inspect(e.event)}"
  end
end

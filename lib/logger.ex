defmodule Exa.Logger do
  # see https://hexdocs.pm/logger/main/Logger.html#module-metadata
  #
  # :application - the current application
  # :mfa - the current module, function and arity
  # :module 
  # :function
  # :file - the current file
  # :line - the current line
  # :pid - the current process identifier
  # :initial_call - the initial call that started the process
  # :registered_name - the process registered name as an atom
  # :process_label - arbitrary term added to a process with Process.set_label/1 
  # :domain - a list of domains for the logged message. 
  # :crash_reason - a two-element tuple with the throw/error/exit reason 
  #                 as first argument and the stacktrace as second. 

  def format(lvl, msg, ts, m) do
    mod = Keyword.get(m, :module)
    fun = Keyword.get(m, :function)
    lin = Keyword.get(m, :line)

    if not is_nil(mod) and not is_nil(fun) and not is_nil(lin) do
      "#{ts(ts)} [#{lvl}] #{mod}&#{fun}:#{lin} #{msg}\n"
    else
      "#{ts(ts)} [#{lvl}] #{msg}\n"
    end
  rescue
    err -> "Error in logger: #{err}\n"
  end

  defp ts({{y, mo, d}, {h, mi, s, _ms}}) do
    "#{y}-#{i2(mo)}-#{i2(d)} #{i2(h)}:#{i2(mi)}:#{i2(s)}"
  end

  defp i2(i) when i < 10, do: "0" <> Integer.to_string(i)
  defp i2(i), do: Integer.to_string(i)
end

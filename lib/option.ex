defmodule Exa.Option do
  @moduledoc """
  Utilities for Keyword options.

  Each access function has two variants, 
  depending on what happens when the option is set to an invalid value:
   - the `!` version raises an error 
   - the unadorned version substitutes the default value
  """

  import Exa.Types

  @spec get_bool!(Keyword.t(), atom()) :: bool()
  def get_bool!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_boolean(opt), do: opt, else: error("boolean", key, opt)
  end

  @spec get_bool(Keyword.t(), atom(), bool()) :: bool()
  def get_bool(opts, key, default \\ false) do
    opt = Keyword.get(opts, key, default)
    if is_boolean(opt), do: opt, else: default
  end

  @spec get_atom!(Keyword.t(), atom()) :: atom()
  def get_atom!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_atom(opt), do: opt, else: error("atom", key, opt)
  end

  @spec get_atom(Keyword.t(), atom(), atom()) :: atom()
  def get_atom(opts, key, default \\ false) do
    opt = Keyword.get(opts, key, default)
    if is_atom(opt), do: opt, else: default
  end

  @spec get_char!(Keyword.t(), atom()) :: char()
  def get_char!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_char(opt), do: opt, else: error("char", key, opt)
  end

  @spec get_char(Keyword.t(), atom(), char()) :: char()
  def get_char(opts, key, default) do
    opt = Keyword.get(opts, key, default)
    if is_char(opt), do: opt, else: default
  end

  @spec get_int!(Keyword.t(), atom()) :: integer()
  def get_int!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_integer(opt), do: opt, else: error("integer", key, opt)
  end

  @spec get_int(Keyword.t(), atom(), integer()) :: integer()
  def get_int(opts, key, default \\ 0) do
    opt = Keyword.get(opts, key, default)
    if is_integer(opt), do: opt, else: default
  end

  @spec get_nonneg_int!(Keyword.t(), atom()) :: integer()
  def get_nonneg_int!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_integer(opt) and opt >= 0, do: opt, else: error("nonneg integer", key, opt)
  end

  @spec get_nonneg_int(Keyword.t(), atom(), integer()) :: integer()
  def get_nonneg_int(opts, key, default \\ 0) do
    opt = Keyword.get(opts, key, default)
    if is_integer(opt) and opt >= 0, do: opt, else: default
  end

  @spec get_pos_int!(Keyword.t(), atom()) :: integer()
  def get_pos_int!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_integer(opt) and opt > 0, do: opt, else: error("positive integer", key, opt)
  end

  @spec get_string!(Keyword.t(), atom()) :: String.t()
  def get_string!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_string(opt), do: opt, else: error("atom or string", key, opt)
  end

  @spec get_string(Keyword.t(), atom(), String.t()) :: String.t()
  def get_string(opts, key, default \\ "") do
    opt = Keyword.get(opts, key, default)
    if is_string(opt), do: opt, else: default
  end

  @spec get_nonempty_string!(Keyword.t(), atom()) :: String.t()
  def get_nonempty_string!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_string(opt) and opt != "", do: opt, else: error("nonempty string", key, opt)
  end

  @spec get_nonempty_string(Keyword.t(), atom(), String.t()) :: String.t()
  def get_nonempty_string(opts, key, default) do
    opt = Keyword.get(opts, key, default)
    if is_string(opt) and opt != "", do: opt, else: default
  end

  @doc "Get an atom or a string."
  @spec get_name!(Keyword.t(), atom()) :: atom() | String.t()
  def get_name!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_atom(opt) or is_string(opt), do: opt, else: error("atom or string", key, opt)
  end

  @doc "Get an atom or a string."
  @spec get_name(Keyword.t(), atom(), atom() | String.t()) :: atom() | String.t()
  def get_name(opts, key, default \\ false) do
    opt = Keyword.get(opts, key, default)
    if is_atom(opt) or is_string(opt), do: opt, else: default
  end

  @spec get_list_atom!(Keyword.t(), atom()) :: [atom()]
  def get_list_atom!(opts, key) do
    opt = Keyword.get(opts, key)

    if is_list(opt) and Enum.all?(opt, &is_atom(&1)) do
      opt
    else
      error("list atom", key, opt)
    end
  end

  @spec get_list_string!(Keyword.t(), atom()) :: [String.t()]
  def get_list_string!(opts, key) do
    opt = Keyword.get(opts, key)

    if is_list(opt) and Enum.all?(opt, &is_string(&1)) do
      opt
    else
      error("list string", key, opt)
    end
  end

  @spec get_list_string(Keyword.t(), atom(), [String.t()]) :: [String.t()]
  def get_list_string(opts, key, default \\ []) do
    opt = Keyword.get(opts, key, default)
    if is_list(opt) and Enum.all?(opt, &is_string(&1)), do: opt, else: default
  end

  @spec get_list_nonempty_string!(Keyword.t(), atom()) :: [String.t()]
  def get_list_nonempty_string!(opts, key) do
    opt = Keyword.get(opts, key)

    if is_list(opt) and Enum.all?(opt, fn s -> is_string(s) and s != "" end) do
      opt
    else
      error("list non-empty string", key, opt)
    end
  end

  @doc "Get list of non-empty names. A name is a string or atom."
  @spec get_list_nonempty_name(Keyword.t(), atom(), [atom() | String.t()]) :: [
          atom() | String.t()
        ]
  def get_list_nonempty_name(opts, key, df \\ []) do
    opt = Keyword.get(opts, key, df)

    if is_list(opt) and
         Enum.all?(opt, fn s ->
           is_atom(s) or (is_string(s) and s != "")
         end) do
      opt
    else
      df
    end
  end

  @spec get_list_nonempty_name!(Keyword.t(), atom()) :: [atom() | String.t()]
  def get_list_nonempty_name!(opts, key) do
    opt = Keyword.get(opts, key)

    if is_list(opt) and
         Enum.all?(opt, fn s ->
           is_atom(s) or (is_string(s) and s != "")
         end) do
      opt
    else
      error("list non-empty string", key, opt)
    end
  end

  @spec get_list_nonempty_string(Keyword.t(), atom(), [String.t()]) :: [String.t()]
  def get_list_nonempty_string(opts, key, df \\ []) do
    opt = Keyword.get(opts, key, df)
    if is_list(opt) and Enum.all?(opt, fn s -> is_string(s) and s != "" end), do: opt, else: df
  end

  @spec get_fun!(Keyword.t(), atom()) :: fun()
  def get_fun!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_function(opt), do: opt, else: error("function", key, opt)
  end

  @spec get_fun(Keyword.t(), atom(), nil | fun()) :: nil | fun()
  def get_fun(opts, key, default \\ nil) do
    opt = Keyword.get(opts, key, default)
    if is_function(opt), do: opt, else: default
  end

  @spec get_map!(Keyword.t(), atom()) :: map()
  def get_map!(opts, key) do
    opt = Keyword.get(opts, key)
    if is_map(opt), do: opt, else: error("map", key, opt)
  end

  @spec get_map(Keyword.t(), atom(), map()) :: map()
  def get_map(opts, key, default \\ %{}) do
    opt = Keyword.get(opts, key, default)
    if is_map(opt), do: opt, else: default
  end

  # private functions

  defp error(name, key, opt) do
    raise ArgumentError, message: "Illegal #{name} '#{key}' option with value '#{opt}'"
  end
end

defmodule Exa.Http do
  @moduledoc """
  A very very basic HTTP client wrapper around Erlang `httpc`.

  Do not use this for dense web service API interaction. 
  The primary use case is protoytyping and testing, 
  such as URL definitions (e.g. Google Maps) and 
  compatibility of content parsers.
  """

  import Exa.Types
  alias Exa.Types, as: E

  # ---------
  # constants
  # ---------

  @google_com "http://google.com"
  @default_timeout 30_000

  # -----
  # types
  # -----

  @type status_code() :: pos_integer()
  @type status() :: String.t()
  @type headers() :: %{atom() => pos_integer() | String.t()}

  @type http_response() ::
          {status_code(), status()}
          | {status_code(), status(), headers(), binary()}

  # ----------------
  # public functions
  # ----------------

  @doc "Just ping if the internet is available."
  @spec internet?() :: bool()
  def internet?() do
    case get(@google_com) do
      {200, "OK"} -> true
      {200, "OK", _, _} -> true
      _ -> false
    end
  end

  # TODO - accept URI argument

  @doc """
  Simple GET request, without any request body.

  A one-shot blocking (synchronous) request-response:
  - Ensure that SSL, INETS and HTTPC daemon are all running.
  - Submit a GET request, wait for the response.
  - Return the status code and status message.
  - For a successful response, parse and interpret a subset of headers:
    `:content_length`, `:mime_type` and optionally the `:charset`.
    Convert charlist values to Strings.
  - Return all these with the request body as binary.
  """
  @spec get(String.t(), E.timeout1()) :: http_response()
  def get(url, timeout \\ @default_timeout) when is_timeout1(timeout) do
    request(:get, {String.to_charlist(url), []}, timeout)
  end

  @doc """
  Simple POST request, with a request body.

  The content type must be an HTTP standard format,
  with the MIME type and an optional character set.
  For example: `"text/html; charset=UTF-8"`.

  The body may be a String or iolist, 
  so it is compatible with output of the 
  EXA `Indent` and `Text` modules.

  A one-shot blocking (synchronous) request-response:
  - Ensure that SSL, INETS and HTTPC daemon are all running.
  - Submit a POST request, wait for the response.
  - Return the status code and status message.
  - For a successful response, parse and interpret a subset of headers:
    `:content_length`, `:mime_type` and optionally the `:charset`.
    Convert charlist values to Strings.
  - Return all these with the request body as binary.
  """
  @spec post(String.t(), String.t(), String.t() | iolist(), E.timeout1()) :: http_response()
  def post(url, content_type, req_body, timeout \\ @default_timeout) when is_timeout1(timeout) do
    url = String.to_charlist(url)
    content_type = String.to_charlist(content_type)
    request = {url, [], content_type, req_body}
    request(:post, request, timeout)
  end

  # -----------------
  # private functions
  # -----------------

  defp request(method, request, timeout) do
    response =
      try do
        ensure_app(:ssl)
        ensure_inets()
        httpc = ensure_inets(:httpc)

        try do
          :httpc.request(method, request, [{:timeout, timeout}], [{:body_format, :binary}])
        after
          stop_inets(:httpc, httpc)
        end
      after
        stop_inets()
        stop_app(:ssl)
      end

    case response do
      {:ok, {{_proto, 200, ~c"OK"}, headers, body}} ->
        content = content(headers)
        body = IO.chardata_to_string(body)
        {200, "OK", content, body}

      {:ok, {{_proto, code, stat}, _headers, _body}} ->
        {code, to_string(stat)}

      {:error, reason} ->
        {500, to_string(reason)}
    end
  end

  defp ensure_app(app) do
    case :application.start(app) do
      :ok -> :ok
      {:error, {:already_started, ^app}} -> :ok
    end
  end

  defp stop_app(app), do: :ok = :application.stop(app)

  defp ensure_inets() do
    case :inets.start() do
      :ok -> :ok
      {:error, {:already_started, :inets}} -> :ok
    end
  end

  defp stop_inets(), do: :inets.stop()

  defp ensure_inets(iapp) do
    case :inets.start(iapp, profile: :default) do
      {:ok, httpc} -> httpc
      {:error, {:already_started, httpc}} -> httpc
    end
  end

  defp stop_inets(iapp, pid), do: :inets.stop(iapp, pid)

  @spec content([{charlist(), charlist()}]) :: map()
  defp content(headers) do
    hdrs = Enum.map(headers, fn {k, v} -> {chars2atom(k), to_string(v)} end)
    len = hdrs |> Keyword.fetch!(:content_length) |> Integer.parse() |> elem(0)
    content = Map.put(%{}, :content_length, len)

    case hdrs |> Keyword.fetch!(:content_type) |> String.split([";", "="]) do
      [mime] ->
        Map.put(content, :mime_type, mime)

      [mime, " charset", charset] ->
        content
        |> Map.put(:mime_type, mime)
        |> Map.put(:charset, charset)
    end
  end

  @spec chars2atom(charlist()) :: atom()
  defp chars2atom(k) do
    k |> to_string() |> String.replace("-", "_") |> String.to_atom()
  end
end

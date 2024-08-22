defmodule Exa.Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :exa_core,
      name: "Exa Core",
      version: "0.1.7",
      elixir: "~> 1.15",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: exa_deps(:exa_core, exa_libs()) ++ local_deps(),
      docs: docs(),
      test_pattern: "*_test.exs",
      dialyzer: [flags: [:no_improper_lists]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :inets]
    ]
  end

  def docs do
    [
      main: "readme",
      output: "doc/api",
      assets: "assets",
      extras: ["README.md"]
    ]
  end

  defp exa_libs() do
    # no exa dependencies - this is the core
    # just a subset of default support libraries
    [:dialyxir, :ex_doc]
  end

  defp local_deps() do
    [
      # test data ----------
      # JSON files for testing compression (no code)
      # needs 'export MIX_ENV=test'
      {:pkg_json, git: "https://github.com/pkg/json.git", only: :dev, runtime: false, app: false}
    ]
  end

  # ---------------------------
  # ***** EXA boilerplate *****
  # shared by all EXA libraries
  # ---------------------------

  # main entry point for dependencies
  # bootstrap with 'mix deps.get exa'
  defp exa_deps(name, libs) do
    case System.argv() do
      ["exa" | _] -> [exa_project()]
      ["format" | _] -> [exa_project()]
      ["deps.get", "exa" | _] -> [exa_project()]
      ["deps.clean" | _] -> do_clean()
      [cmd | _] -> do_deps(cmd, name, libs)
    end
  end

  defp do_clean() do
    Enum.each([:local, :main, :tag], fn s -> s |> deps_file() |> File.rm() end)
    [exa_project()]
  end

  defp do_deps(cmd, name, libs) do
    scope = arg_build()
    deps_path = deps_file(scope)

    if not File.exists?(deps_path) do
      # invoke the exa project mix task to generate dependencies
      exa_args = Enum.map([:exa, scope | libs], &to_string/1)

      case System.cmd("mix", exa_args) do
        {_out, 0} ->
          :ok

        {out, n} ->
          args = Enum.join(exa_args, " ")
          raise RuntimeError, message: "Failed 'mix #{args}' status #{n} '#{out}'"
      end

      if not File.exists?(deps_path) do
        raise RuntimeError, message: "Cannot create dependency file: #{deps_path}"
      end
    end

    deps = deps_path |> Code.eval_file() |> elem(0)

    if String.starts_with?(cmd, ["deps", "compile"]) do
      IO.inspect(deps, label: "#{name} #{scope}")
    end

    [exa_project() | deps]
  end

  # the deps literal file to be written for each scope
  defp deps_file(scope), do: Path.join([".", "deps", "deps_#{scope}.ex"])

  # parse the build scope from:
  # - mix command line --build option
  # - MIX_BUILD system environment variable
  # - default to "tag"
  defp arg_build() do
    default =
      case System.fetch_env("MIX_BUILD") do
        :error -> "tag"
        {:ok, mix_build} -> mix_build
      end

    System.argv()
    |> tl()
    |> OptionParser.parse(strict: [build: :string])
    |> elem(0)
    |> Keyword.get(:build, default)
    |> String.to_atom()
  end

  # the main exa umbrella library project
  # provides the 'mix exa' task to generate dependencies
  defp exa_project() do
    {
      :exa,
      git: "https://github.com/red-jade/exa.git",
      branch: "main",
      only: [:dev, :test],
      runtime: false
    }
  end
end

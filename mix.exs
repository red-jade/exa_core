defmodule Exa.Core.MixProject do
  use Mix.Project

  @lib :exa_core
  @name "Exa Core"
  @ver "0.2.2"

  # umbrella project
  @exa {:exa,
        git: "https://github.com/red-jade/exa.git",
        branch: "main",
        only: [:dev, :test],
        runtime: false}

  # dependency config code
  @mix_util Path.join(["deps", "exa", "mix_util.ex"])

  def project do
    exa_deps =
      if File.regular?(@mix_util) do
        if not Code.loaded?(Exa.MixUtil) do
          [{Exa.MixUtil, _}] = Code.compile_file(@mix_util)
        end

        Exa.MixUtil.exa_deps(@lib, exa_libs())
      else
        # bootstrap
        []
      end

    [
      app: @lib,
      name: @name,
      version: @ver,
      elixir: "~> 1.17",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: [@exa | exa_deps] ++ local_deps(),
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
      assets: %{"assets" => "assets"},
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
end

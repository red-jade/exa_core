defmodule Exa.MixProject do
  use Mix.Project

  def project do
    [
      app: :exa,
      name: "Exa",
      version: "0.1.7",
      elixir: "~> 1.15",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: deps()++deps(:support),
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

  # runtime code dependencies ----------
  defp deps() do
    [
      # ... tumbleweed ...
    ]
  end

  defp deps(:support) do
    [
      # building, documenting, testing ----------

      # typechecking
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},

      # documentation
      {:ex_doc, "~> 0.30", only: [:dev, :test], runtime: false},

      # benchmarking
      # {:benchee, "~> 1.0", only: [:dev, :test]},

      # test data ----------

      # JSON files for testing (no code)
      {:pkg_json, git: "https://github.com/pkg/json.git", only: :dev, runtime: false, app: false}
    ]
  end
end

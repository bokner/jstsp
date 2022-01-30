defmodule Jstsp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ssp,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {SSP.Application, []},
      extra_applications: [:logger, :cubdb]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:solverl, git: "https://github.com/bokner/solverl.git"},
      #{:solverl, path: "/Users/bokner/projects/solverl"},
      {:csv, "~> 2.4"},
      {:cubdb, "~> 1.1"}
    ]
  end
end

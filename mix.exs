defmodule AxonRLDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :axon_rl_demo,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :xmerl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:httpoison, "~> 1.8"},
      {:poison, "~> 4.0"},
      {:deque, "~> 1.2"},

      {:axon, "~> 0.1.0-dev", git: "git@github.com:elixir-nx/axon.git", override: true},
      {:exla, "~> 0.1.0-dev", git: "git@github.com:elixir-nx/nx", sparse: "exla", override: true},
      {:nx, "~> 0.1.0-dev", git: "git@github.com:elixir-nx/nx", sparse: "nx", override: true},
    ]
  end
end

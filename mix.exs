defmodule Ping.MixProject do
  use Mix.Project

  def project do
    [
      app: :ping,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Ping.Application, []},
      extra_applications: [:logger, :cowboy, :plug]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:tesla, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:plug, "~> 1.14"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end

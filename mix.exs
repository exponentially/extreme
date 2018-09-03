defmodule Extreme.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extreme,
      version: "1.0.0+beta1",
      elixir: "~> 1.5",
      elixirc_paths: _elixirc_paths(Mix.env()),
      source_url: "https://github.com/exponentially/extreme",
      description: """
      Elixir TCP adapter for EventStore.
      """,
      package: _package(),
      start_permanent: Mix.env() == :prod,
      deps: _deps()
    ]
  end

  def application do
    [
      # mod: {App, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp _elixirc_paths(:test), do: ["lib", "test/support"]
  defp _elixirc_paths(_), do: ["lib"]

  defp _deps do
    [
      {:protobuf, "~> 0.5.3"},
      {:elixir_uuid, "~> 1.2"}
      # {:ex_doc, "~> 0.19", only: :test},
      # {:earmark, "~> 1.2", only: :test},
      # {:inch_ex, "~> 1.0", only: :test},
      # {:excoveralls, "~> 0.9", only: :test},
    ]
  end

  defp _package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Milan Burmaja", "Milan Jaric"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/exponentially/extreme"}
    ]
  end
end

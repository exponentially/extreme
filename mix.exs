defmodule Extreme.Mixfile do
  use Mix.Project

  def project do
    [app: :extreme,
     version: "0.10.4",
     elixir: "~> 1.3.0 or ~> 1.4.0 or ~> 1.5.0",
     source_url: "https://github.com/exponentially/extreme",
     description: """
     Elixir TCP adapter for EventStore.
     """,
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     deps: deps()]
  end

  def application do
    [
      applications: [:logger,
        :exprotobuf, :uuid, :gpb, :httpoison, :poison]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.11"},
      {:poison, "~> 2.2 or ~> 3.0"},
      {:exprotobuf, "~> 1.2"},
      {:uuid, "~> 1.1.4" },
      {:ex_doc, "~> 0.16.2", only: [:test]},
      {:earmark, "~> 1.2.2", only: [:test]},
      {:inch_ex, "~> 0.5.6", only: :docs},
      {:excoveralls, "~> 0.6", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
    ]
  end

  defp package do
    [
      files: ["lib", "include", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Milan Burmaja", "Milan Jaric"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/exponentially/extreme"}
    ]
  end
end

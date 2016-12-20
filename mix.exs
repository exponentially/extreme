defmodule Extreme.Mixfile do
  use Mix.Project

  def project do
    [app: :extreme,
     version: "0.7.1",
     elixir: ">= 1.0.0 and ~> 1.3.0",
     source_url: "https://github.com/exponentially/extreme",
     description: """
     Elixir TCP adapter for EventStore.
     """,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      applications: [:logger, 
        :exprotobuf, :uuid, :gpb, :httpoison, :poison]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.4 or ~> 3.0.0"},
      {:exprotobuf, "~> 1.0.0"},
      {:uuid, "~> 1.1.4" },
      {:ex_doc, ">= 0.11.4", only: [:test]},
      {:earmark, ">= 0.0.0", only: [:test]},
      {:exrm, "~> 1.0.3", override: true, only: :test},
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

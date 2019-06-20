defmodule Extreme.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extreme,
      version: "0.13.3",
      elixir: "~> 1.0",
      source_url: "https://github.com/exponentially/extreme",
      description: """
      Elixir TCP adapter for EventStore.
      """,
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.2"},
      {:poison, "~> 2.2 or ~> 3.0 or ~> 4.0"},
      {:exprotobuf, "~> 1.2"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, "~> 0.19", only: :test},
      {:earmark, "~> 1.2", only: :test},
      {:inch_ex, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.9", only: :test},
      {:mix_test_watch, "~> 0.8", only: :dev}
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

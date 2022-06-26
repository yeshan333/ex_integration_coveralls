defmodule ExIntegrationCoveralls.MixProject do
  use Mix.Project

  @source_url "https://github.com/yeshan333/ex_integration_coveralls"

  def project do
    [
      app: :ex_integration_coveralls,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "ExIntegrationCoveralls",
      description: description(),
      homepage_url: @source_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :tools],
      application: [:httpoison]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures/test_missing.ex"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.8"},
      {:meck, "~> 0.8", only: :test},
      {:mock, "~> 0.3.6", only: :test},
      {:ex_doc, "~> 0.18", only: :dev},
    ]
  end

  defp description() do
    "A library for integration test code line-level coverage analysis."
  end

  defp package do
    [
      maintainers: ["yeshan333"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end

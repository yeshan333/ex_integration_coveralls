defmodule ExIntegrationCoveralls.MixProject do
  use Mix.Project

  @source_url "https://github.com/yeshan333/ex_integration_coveralls"

  def project do
    [
      app: :ex_integration_coveralls,
      version: "0.8.0",
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
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env:
        cli_env_for(:test, [
          "coveralls",
          "coveralls.detail",
          "coveralls.html",
          "coveralls.json",
          "coveralls.post"
        ])
    ]
  end

  defp cli_env_for(env, tasks) do
    Enum.reduce(tasks, [], fn key, acc -> Keyword.put(acc, :"#{key}", env) end)
  end

  def application do
    [
      extra_applications: [:logger, :tools],
      application: [:httpoison],
      mod: {ExIntegrationCoveralls.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures/test_missing.ex"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.8"},
      {:plug_cowboy, "~> 2.5"},
      {:meck, "~> 0.8", only: :test},
      {:mock, "~> 0.3.6", only: :test},
      {:ex_doc, "~> 0.18", only: :dev},
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:husky, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    "A library for run-time system code line-level coverage analysis. You can use it to evulate the intergration test coverage."
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

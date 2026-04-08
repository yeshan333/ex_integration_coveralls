defmodule ReleaseDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :release_demo,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        release_demo: [
          strip_beams: [keep: ["Docs", "Dbgi"]],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ReleaseDemo.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_integration_coveralls, path: "../.."}
    ]
  end
end

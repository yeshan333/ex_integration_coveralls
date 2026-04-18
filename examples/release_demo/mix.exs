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
          applications: [runtime_tools: :permanent],
          steps: [:assemble, &copy_app_sources/1]
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

  # Copy source files into the release so that coverage analysis can read them at runtime.
  # Without source files, Stats.generate_coverage cannot count lines per file.
  defp copy_app_sources(release) do
    release_lib = Path.join(release.path, "lib")

    for {app, src} <- [{:release_demo, "lib"}, {:dep_lib, "../dep_lib/lib"}] do
      [target] = Path.wildcard(Path.join(release_lib, "#{app}-*"))
      File.cp_r!(src, Path.join(target, "lib"))
    end

    release
  end

  defp deps do
    [
      {:ex_integration_coveralls, path: "../.."},
      {:dep_lib, path: "../dep_lib"}
    ]
  end
end

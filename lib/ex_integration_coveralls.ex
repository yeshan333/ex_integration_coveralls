defmodule ExIntegrationCoveralls do
  @moduledoc """
  Documentation for `ExIntegrationCoveralls`.
  """
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.Stats

  def execute(compiled_beam_dir_path) do
    Cover.compile(compiled_beam_dir_path)
  end

  def exit do
    Cover.stop()
  end

  def reset_coverage_data do
    Cover.reset()
  end

  @doc """
  Get an overall integration test coverage rate of an OTP application

  ## Parameters
  - compile_time_source_lib_abs_path: source code project abs path in compile-time machine.
  - source_lib_absolute_path: source code project abs path in run-time machine.
  """
  def get_total_coverage(
        compile_time_source_lib_abs_path \\ File.cwd!(),
        source_code_abs_path \\ File.cwd!()
      ) do
    stats =
      Cover.modules(source_code_abs_path)
      |> Stats.report(compile_time_source_lib_abs_path, source_code_abs_path)
      |> Stats.transform_cov()

    Map.get(stats, :coverage)
  end

  @doc """
  Get an overall integration test coverage analysis report of an OTP application

  ## Parameters
  - compile_time_source_lib_abs_path: source code project abs path in compile-time machine.
  - source_lib_absolute_path: source code project abs path in run-time machine.

  ## Examples

      %{
        coverage: 50,
        files: [
          %Stats.Source{
            coverage: 50,
            filename: "test/fixtures/test.ex",
            hits: 1,
            misses: 1,
            sloc: 2,
            source: [
              %Stats.Line{coverage: 0, source: "defmodule Test do"},
              %Stats.Line{coverage: 1, source: "  def test do"},
              %Stats.Line{coverage: nil, source: "  end"},
              %Stats.Line{coverage: nil, source: "end"}
            ]
          }
        ],
        hits: 1,
        misses: 1,
        sloc: 2
      }

  """
  def get_coverage_report(
        compile_time_source_lib_abs_path \\ File.cwd!(),
        source_code_abs_path \\ File.cwd!()
      ) do
    stats =
      Cover.modules(source_code_abs_path)
      |> Stats.report(compile_time_source_lib_abs_path, source_code_abs_path)
      |> Stats.transform_cov()

    stats
  end
end

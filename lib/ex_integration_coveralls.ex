defmodule ExIntegrationCoveralls do
  @moduledoc """
  Run-time system code line-level coverage analysis.
  """
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.CoverageCiPoster
  alias ExIntegrationCoveralls.PathReader

  @doc """
  Enable run-time env elxiir application coverage collection.

  ## Parameters
  - app_name: application name, It is a string.
  """
  def start_app_cov(app_name) do
    {_, _, app_beam_dir} = PathReader.get_app_cover_path(app_name)

    execute(app_beam_dir)
  end

  @doc """
  Get run-time env elxiir application total coverage.

  ## Parameters
  - app_name: application name, It is a string.
  """
  def get_app_total_cov(app_name) do
    {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, _} =
      PathReader.get_app_cover_path(app_name)

    get_total_coverage(compile_time_source_lib_abs_path, run_time_source_lib_abs_path)
  end

  @doc """
  Post run-time env elxiir application coverage to remote coverage service.

  ## Parameters
  - app_name: application name, It is a string.
  - url: CI receive stats address
  - extends_post_params: use to transform stats which CI service can acceptable form
  """
  def post_app_cov_to_ci(url, extends_post_params, app_name) do
    {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, _} =
      PathReader.get_app_cover_path(app_name)

    post_cov_stats_to_ud_ci(
      url,
      extends_post_params,
      compile_time_source_lib_abs_path,
      run_time_source_lib_abs_path
    )
  end

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

  @doc """
  Post coverage stats to User-Domain Cover CI Service.

  ## Parameters
  - url: CI receive stats address
  - extends_post_params: use to transform stats which CI service can acceptable form
  - compile_time_source_lib_abs_path: source code project abs path in compile-time machine.
  - source_lib_absolute_path: source code project abs path in run-time machine.
  """
  def post_cov_stats_to_ud_ci(
        url,
        extends_post_params,
        compile_time_source_lib_abs_path \\ File.cwd!(),
        source_code_abs_path \\ File.cwd!()
      ) do
    CoverageCiPoster.post_stats_to_cover_ci(
      url,
      extends_post_params,
      compile_time_source_lib_abs_path,
      source_code_abs_path
    )
  end
end

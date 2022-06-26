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

  @doc """
  Get an overall integration test coverage analysis of an OTP application

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
end

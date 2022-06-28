defmodule ExIntegrationCoveralls.CoverageCiPoster do
  @moduledoc """
  Handler for posting coverage data to Internal CI Service.
  """
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Json
  alias ExIntegrationCoveralls.Poster

  @doc """
  Post stats to coverage CI.

  ## Parameters
  - url: CI receive stats address
  - extends_post_params: use to transform stats which CI service can acceptable form
  - compile_time_source_lib_abs_path: source code project abs path in compile-time machine.
  - source_lib_absolute_path: source code project abs path in run-time machine.
  """
  def post_stats_to_cover_ci(
        url,
        extends_post_params,
        compile_time_source_lib_abs_path \\ File.cwd!(),
        source_code_abs_path \\ File.cwd!()
      ) do
    stats =
      get_coverage_stats(compile_time_source_lib_abs_path, source_code_abs_path)
      |> stats_transformer(extends_post_params)

    body = Json.generate_json_output(stats)
    Poster.post_to_coverage_services_center(url, body)
  end

  @doc """
  Get coverage stats.

  ## Return
  A map array.

  ## Examples
      [{"lib/hello.ex", [ nil, 0, nil, 0, nil, 1]}, ...]
  """
  def get_coverage_stats(
        compile_time_source_lib_abs_path,
        source_code_abs_path
      ) do
    stats =
      Cover.modules(source_code_abs_path)
      |> Stats.calculate_stats(compile_time_source_lib_abs_path)
      |> Stats.generate_coverage(source_code_abs_path)

    stats
  end

  @doc """
  Transform stats to CI acceptable form.

  ## Parameters
  - stats: get_coverage_stats() return value
  """
  def stats_transformer(stats, extends) do
    # %{"lib/hello.ex" => %{ 1 => 3, 2 => 0, 3 => 1}}
    files_map =
      Enum.map(stats, fn item ->
        {file_path, line_cov_arr} = item
        file_coverage_map(file_path, line_cov_arr)
      end)
      |> Map.new()

    Map.put_new(extends, :files, files_map)
  end

  # Return value like this: {"lib/hello.ex", %{ 1 => 3, 2 => 0, 3 => 1}}
  defp file_coverage_map(file_path, line_cov_arr) do
    line_cov_map =
      Enum.with_index(line_cov_arr, fn element, index ->
        [index + 1, transform_nil_to_zero(element)]
      end)
      |> Map.new(fn [k, v] -> {k, v} end)

    {file_path, line_cov_map}
  end

  defp transform_nil_to_zero(value) do
    cond do
      value == nil -> 0
      value -> value
    end
  end
end

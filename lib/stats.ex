defmodule ExIntegrationCoveralls.Stats do
  @moduledoc """
  Provide calculation logics of coverage stats.
  """
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader

  @doc """
  Calculate the statistical information for the specified list of modules.
  It uses :cover.analyse for getting the information.

  ## Parameters
  - modules: Cover.modules() return value

  ## Returns
  a Map stores the number of executions of executable line in the source file.
  \neg: %{"test/fixtures/test1.ex" => %{1 => 0, 2 => 1}, "test/fixtures/test2.ex" => %{1 => 0, 2 => 0}}
  """
  def calculate_stats(modules, source_lib_absolute_path \\ File.cwd!()) do
    Enum.reduce(modules, Map.new(), fn module, dict ->
      {:ok, lines} = Cover.analyze(module)
      # calc the number of executions
      analyze_lines(lines, dict, source_lib_absolute_path)
    end)
  end

  defp analyze_lines(lines, module_hash, source_lib_absolute_path) do
    Enum.reduce(lines, module_hash, fn {{module, line}, count}, module_hash ->
      add_counts(module_hash, module, line, count, source_lib_absolute_path)
    end)
  end

  defp add_counts(module_hash, module, line, count, source_lib_absolute_path) do
    path = Cover.module_path(module, source_lib_absolute_path)
    count_hash = Map.get(module_hash, path, Map.new())

    Map.put(
      module_hash,
      path,
      Map.put(count_hash, line, max(Map.get(count_hash, line, 0), count))
    )
  end

  @doc """
  Read source code
  """
  def read_source(file_path) do
    file_path |> File.read!() |> trim_empty_prefix_and_suffix
  end

  @doc """
  Returns total line counts of the specified source file.
  """
  def get_source_line_count(file_path) do
    read_source(file_path) |> count_lines
  end

  @doc """
  Remove the front and back blank lines
  """
  def trim_empty_prefix_and_suffix(string) do
    string = Regex.replace(~r/\n\z/m, string, "")
    Regex.replace(~r/\A\n/m, string, "")
  end

  defp count_lines(string) do
    1 + (Regex.scan(~r/\n/i, string) |> length)
  end

  @doc """
  Generate coverage, based on the pre-calculated statistic information.

  ## Parameters
  - hash: calculate_stats() return value
  - base_path: the source code project absolute path

  ## Returns
  A tuple array. The first element of the tuple is the source code path
  The second element of the tuple stores the number of times each row was executed.
  The nil means it's not an executable line.
  Non-negative numbers represent the number of times each line  of source code is executed.
  \neg: [{"lib/hello.ex", [ nil, 0, nil, 0, nil, 1]}, ...]
  """
  def generate_coverage(hash, base_path \\ File.cwd!()) do
    keys = Map.keys(hash)

    Enum.map(keys, fn file_path ->
      total = get_source_line_count(PathReader.expand_path(file_path, base_path))
      {file_path, do_generate_coverage(Map.fetch!(hash, file_path), total, [])}
    end)
  end

  defp do_generate_coverage(_hash, 0, acc), do: acc

  defp do_generate_coverage(hash, index, acc) do
    count = Map.get(hash, index, nil)
    do_generate_coverage(hash, index - 1, [count | acc])
  end

  @doc """
  Generate objects which stores source-file and coverage stats information.

  ## Parameters
  - coverage generate_coverage() return value

  ## Returns
  A map array.
  \neg: [%{name: "lib/hello.ex", source: "defmodule Test do\\n  def test do\\n  end\\nend", [0, 1, nil, nil]}]
  """
  def generate_source_info(coverage, base_path \\ File.cwd!()) do
    Enum.map(coverage, fn {file_path, stats} ->
      %{
        name: file_path,
        source: read_source(PathReader.expand_path(file_path, base_path)),
        coverage: stats
      }
    end)
  end
end

defmodule ExIntegrationCoveralls.Stats do
  @moduledoc """
  Provide calculation logics of coverage stats.
  """
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader

  defmodule Source do
    @moduledoc """
    Stores count information for a file and all source lines.
    """

    @derive [Poison.Encoder]
    defstruct filename: "", coverage: 0, sloc: 0, hits: 0, misses: 0, source: []
  end

  defmodule Line do
    @moduledoc """
    Stores count information and source for a single line.
    """

    @derive [Poison.Encoder]
    defstruct coverage: nil, source: ""
  end

  @doc """
  Report the statistical information for the specified module.

  ## Parameters
  - compile_time_source_lib_abs_path: source code project abs path in compile-time machine.
  - source_lib_absolute_path: source code project abs path in run-time machine.

  ## Returns
  Return value like this:

      [
        %{
          coverage: [0, 1, nil, nil],
          name: "lib/hello.ex",
          source: "defmodule Test do\\n  def test do\\n  end\\nend"
        }
      ]
  """
  def report(modules, compile_time_source_lib_abs_path, source_lib_absolute_path) do
    calculate_stats(modules, compile_time_source_lib_abs_path)
    |> generate_coverage(source_lib_absolute_path)
    |> generate_source_info(source_lib_absolute_path)
  end

  @doc """
  Calculate the statistical information for the specified list of modules.
  It uses :cover.analyse for getting the information.

  ## Parameters
  - modules: Cover.modules() return value

  ## Returns
  a Map stores the number of executions of executable line in the source file.

  ## Examples

      %{
        "test/fixtures/test1.ex" => %{1 => 0, 2 => 1},
        "test/fixtures/test2.ex" => %{1 => 0, 2 => 0}
      }
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

  ## Examples

      [{"lib/hello.ex", [ nil, 0, nil, 0, nil, 1]}, ...]
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
  - coverage: generate_coverage() return value

  ## Returns
  A map array.

  ## Examples
  Return value like this:

      [
        %{
          coverage: [0, 1, nil, nil],
          name: "lib/hello.ex",
          source: "defmodule Test do\\n  def test do\\n  end\\nend"
        }
      ]
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

  @doc """
  Organize coverage data in a human-readable way.

  ## Parameters
  - stats: generate_source_info() return value

  ## Return
  A map.

  ## Examples
  Return value link this:

      %{
        coverage: 50,
        files: [
          %ExIntegrationCoveralls.Stats.Source{
            coverage: 50,
            filename: "test/fixtures/test.ex",
            hits: 1,
            misses: 1,
            sloc: 2,
            source: [
              %ExIntegrationCoveralls.Stats.Line{coverage: 0, source: "defmodule Test do"},
              %ExIntegrationCoveralls.Stats.Line{coverage: 1, source: "  def test do"},
              %ExIntegrationCoveralls.Stats.Line{coverage: nil, source: "  end"},
              %ExIntegrationCoveralls.Stats.Line{coverage: nil, source: "end"}
            ]
          }
        ],
        hits: 1,
        misses: 1,
        sloc: 2
      }
  """
  def transform_cov(stats) do
    stats = Enum.sort(stats, fn x, y -> x[:name] <= y[:name] end)

    files = Enum.map(stats, &populate_file/1)
    {relevant, hits, misses} = Enum.reduce(files, {0, 0, 0}, &reduce_file_counts/2)
    covered = relevant - misses

    %{
      coverage: get_coverage(relevant, covered),
      sloc: relevant,
      hits: hits,
      misses: misses,
      files: files
    }
  end

  defp populate_file(stat) do
    coverage = stat[:coverage]
    source = map_source(stat[:source], coverage)
    relevant = Enum.count(coverage, fn e -> e != nil end)
    hits = Enum.reduce(coverage, 0, fn e, acc -> (e || 0) + acc end)
    misses = Enum.count(coverage, fn e -> e == 0 end)
    covered = relevant - misses

    %Source{
      filename: stat[:name],
      coverage: get_coverage(relevant, covered),
      sloc: relevant,
      hits: hits,
      misses: misses,
      source: source
    }
  end

  defp map_source(source, coverage) do
    source
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.map(&populate_source(&1, coverage))
  end

  defp populate_source({line, i}, coverage) do
    %Line{coverage: Enum.at(coverage, i), source: line}
  end

  defp get_coverage(relevant, covered) do
    value =
      case relevant do
        0 -> 100.0
        _ -> covered / relevant * 100
      end

    if value == trunc(value) do
      trunc(value)
    else
      Float.round(value, 1)
    end
  end

  defp reduce_file_counts(%{sloc: sloc, hits: hits, misses: misses}, {s, h, m}) do
    {s + sloc, h + hits, m + misses}
  end
end

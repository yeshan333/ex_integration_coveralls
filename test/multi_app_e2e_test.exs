defmodule ExIntegrationCoveralls.MultiAppE2ETest do
  @moduledoc """
  End-to-end tests for multi-app coverage collection.
  These tests use the real :cover module — no mocks.
  """
  use ExUnit.Case, async: false

  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.CoverageCiPoster
  alias ExIntegrationCoveralls.PathReader

  @moduletag :real_cover

  @hello_beam_dir PathReader.expand_path("test/fixtures/hello/ebin")
  @hello_compile_root "/private/tmp/hello"
  @hello_runtime_root PathReader.expand_path("test/fixtures/hello")

  # Call Hello.hello/0 without triggering compile-time "undefined module" warning.
  # The Hello module is loaded at runtime via :cover.compile_beam_directory.
  defp call_hello, do: apply(Hello, :hello, [])

  setup do
    on_exit(fn -> Cover.stop() end)

    project_ebin = Application.app_dir(:ex_integration_coveralls, "ebin")
    project_root = File.cwd!()

    {:ok, project_ebin: project_ebin, project_root: project_root}
  end

  describe "multi-dir compilation" do
    test "compiles modules from both beam directories", ctx do
      result = Cover.compile([@hello_beam_dir, ctx.project_ebin])

      assert is_list(result)
      assert {:ok, Hello} in result

      # At least one project module is compiled
      project_modules =
        Enum.filter(result, fn
          {:ok, mod} -> mod != Hello and String.starts_with?(Atom.to_string(mod), "Elixir.ExIntegrationCoveralls")
          _ -> false
        end)

      assert length(project_modules) > 0

      # No errors
      errors = Enum.filter(result, fn {:ok, _} -> false; _ -> true end)
      assert errors == []
    end
  end

  describe "modules_for_compile_root/1 partitioning" do
    test "correctly separates modules by compile-time root", ctx do
      Cover.compile([@hello_beam_dir, ctx.project_ebin])

      hello_modules = Cover.modules_for_compile_root(@hello_compile_root)
      assert hello_modules == [Hello]

      project_modules = Cover.modules_for_compile_root(ctx.project_root)
      assert length(project_modules) > 0
      refute Hello in project_modules

      # Two sets are disjoint
      hello_set = MapSet.new(hello_modules)
      project_set = MapSet.new(project_modules)
      assert MapSet.disjoint?(hello_set, project_set)
    end
  end

  describe "per-app stats collection after code execution" do
    test "coverage data respects partitioning", ctx do
      Cover.compile([@hello_beam_dir, ctx.project_ebin])
      call_hello()

      # Hello partition: line 16 was executed
      hello_modules = Cover.modules_for_compile_root(@hello_compile_root)
      hello_stats = Stats.calculate_stats(hello_modules, @hello_compile_root)
      assert Map.has_key?(hello_stats, "lib/hello.ex")
      assert hello_stats["lib/hello.ex"][16] > 0

      # Project partition: does NOT contain "lib/hello.ex"
      project_modules = Cover.modules_for_compile_root(ctx.project_root)
      project_stats = Stats.calculate_stats(project_modules, ctx.project_root)
      assert map_size(project_stats) > 0
      refute Map.has_key?(project_stats, "lib/hello.ex")
    end
  end

  describe "get_total_coverage_multi/1" do
    test "returns merged coverage percentage from multiple apps", ctx do
      Cover.compile([@hello_beam_dir, ctx.project_ebin])
      call_hello()

      path_pairs = [
        {@hello_compile_root, @hello_runtime_root},
        {ctx.project_root, ctx.project_root}
      ]

      result = ExIntegrationCoveralls.get_total_coverage_multi(path_pairs)
      assert is_number(result)
      assert result >= 0 and result <= 100
      # Hello is 100% covered, so total > 0
      assert result > 0
    end
  end

  describe "get_coverage_report_multi/1" do
    test "report contains files from both apps with correct structure", ctx do
      Cover.compile([@hello_beam_dir, ctx.project_ebin])
      call_hello()

      path_pairs = [
        {@hello_compile_root, @hello_runtime_root},
        {ctx.project_root, ctx.project_root}
      ]

      report = ExIntegrationCoveralls.get_coverage_report_multi(path_pairs)

      assert is_map(report)
      assert Map.has_key?(report, :coverage)
      assert Map.has_key?(report, :sloc)
      assert Map.has_key?(report, :hits)
      assert Map.has_key?(report, :misses)
      assert Map.has_key?(report, :files)

      filenames = Enum.map(report.files, & &1.filename)
      assert "lib/hello.ex" in filenames

      # Project files are also present
      project_files = Enum.filter(filenames, fn f -> f != "lib/hello.ex" end)
      assert length(project_files) > 0

      # Hello module has 100% coverage (all 3 executable lines hit)
      hello_file = Enum.find(report.files, &(&1.filename == "lib/hello.ex"))
      assert hello_file.coverage == 100
      assert hello_file.sloc == 3
      assert hello_file.misses == 0
    end
  end

  describe "CoverageCiPoster.get_coverage_stats_multi/1" do
    test "returns merged line coverage tuples from both apps", ctx do
      Cover.compile([@hello_beam_dir, ctx.project_ebin])
      call_hello()

      path_pairs = [
        {@hello_compile_root, @hello_runtime_root},
        {ctx.project_root, ctx.project_root}
      ]

      stats = CoverageCiPoster.get_coverage_stats_multi(path_pairs)
      assert is_list(stats)

      file_paths = Enum.map(stats, fn {path, _} -> path end)
      assert "lib/hello.ex" in file_paths

      # Project files are present
      other_files = Enum.filter(file_paths, &(&1 != "lib/hello.ex"))
      assert length(other_files) > 0

      # Hello's line coverage array has 23 elements (source file is 23 lines)
      {_, hello_coverage} = Enum.find(stats, fn {p, _} -> p == "lib/hello.ex" end)
      assert length(hello_coverage) == 23
      # line 16 (0-indexed: 15) was executed
      assert Enum.at(hello_coverage, 15) > 0
    end
  end

  describe "single-app degenerate case" do
    test "multi functions work correctly with one path pair" do
      Cover.compile([@hello_beam_dir])
      call_hello()

      path_pairs = [{@hello_compile_root, @hello_runtime_root}]

      coverage = ExIntegrationCoveralls.get_total_coverage_multi(path_pairs)
      assert coverage == 100

      report = ExIntegrationCoveralls.get_coverage_report_multi(path_pairs)
      assert length(report.files) == 1
      assert hd(report.files).filename == "lib/hello.ex"
    end
  end

  describe "zero coverage in multi-app context" do
    test "unexercised code shows 0% coverage" do
      Cover.compile([@hello_beam_dir])
      # Do NOT call call_hello()

      path_pairs = [{@hello_compile_root, @hello_runtime_root}]

      report = ExIntegrationCoveralls.get_coverage_report_multi(path_pairs)
      hello_file = hd(report.files)
      assert hello_file.coverage == 0
      assert hello_file.misses == 3
      assert hello_file.hits == 0
    end
  end
end

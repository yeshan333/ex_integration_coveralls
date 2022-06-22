defmodule ExIntegrationCoveralls.StatsTest do
  use ExUnit.Case, async: false
  import Mock
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader

  @stats [{{Foo, 1}, 0}, {{Foo, 2}, 1}]
  @source "test/fixtures/test.ex"
  @count_hash Enum.into([{1, 0}, {2, 1}], Map.new())
  @module_hash Enum.into([{"test/fixtures/test.ex", @count_hash}], Map.new())
  @counts [0, 1, nil, nil]
  @coverage [{"test/fixtures/test.ex", @counts}]

  @calculate_stats %{"/private/tmp/hello/lib/hello.ex" => %{0 => 0, 16 => 0, 18 => 0, 20 => 0}}
  @calculate_stats_with_path %{"lib/hello.ex" => %{0 => 0, 16 => 0, 18 => 0, 20 => 0}}
  @source_file_path "test/fixtures/hello/lib/hello.ex"
  @source_content "defmodule Hello do\n  @moduledoc \"\"\"\n  Documentation for `Hello`.\n  \"\"\"\n\n  @doc \"\"\"\n  Hello world.\n\n  ## Examples\n\n      iex> Hello.hello()\n      :world\n\n  \"\"\"\n  def hello do\n    File.cwd!()\n    :world\n    File.cwd!()\n    :hello\n    File.cwd!()\n    :world\n  end\nend"
  @beam_file_path "test/fixtures/hello/beams/hello_ebin"
  @source_code_project_base_path PathReader.expand_path("test/fixtures/hello")
  @module_line_cover_counts [
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    0,
    nil,
    0,
    nil,
    0,
    nil,
    nil,
    nil
  ]
  @module_line_cover_stats [
    {"lib/hello.ex", @module_line_cover_counts}
  ]
  @module_source_info [
    %{
      name: "lib/hello.ex",
      source: @source_content,
      coverage: @module_line_cover_counts
    }
  ]

  @tag :real_cover
  test "calculate stats" do
    _cover_modules_status = Cover.compile(PathReader.expand_path(@beam_file_path))

    cover_modules = Cover.modules(PathReader.expand_path(@beam_file_path))

    assert(
      Stats.calculate_stats(cover_modules, "/private/tmp/hello") ==
        @calculate_stats_with_path
    )

    assert(Stats.calculate_stats(cover_modules) == @calculate_stats)

    Cover.stop()
  end

  test_with_mock "calculate stats - mock", Cover,
    analyze: fn _ -> {:ok, @stats} end,
    module_path: fn _, _ -> @source end do
    assert(Stats.calculate_stats([Foo]) == @module_hash)
  end

  test "read source code file" do
    assert(Stats.read_source(PathReader.expand_path(@source_file_path)) == @source_content)
  end

  test "get source line count" do
    assert(Stats.get_source_line_count(PathReader.expand_path(@source_file_path)) == 23)
  end

  @tag :real_cover
  test "generate coverage" do
    _cover_modules = Cover.compile(PathReader.expand_path(@beam_file_path))

    cover_modules = Cover.modules(PathReader.expand_path(@source_file_path))

    pre_calculated_stats = Stats.calculate_stats(cover_modules, "/private/tmp/hello")

    assert(pre_calculated_stats == @calculate_stats_with_path)

    assert(
      Stats.generate_coverage(pre_calculated_stats, @source_code_project_base_path) ==
        @module_line_cover_stats
    )

    Cover.stop()
  end

  test_with_mock "generate coverage - mock", Cover, module_path: fn _ -> @source end do
    assert(Stats.generate_coverage(@module_hash) == @coverage)
  end

  @tag :real_cover
  test "generate source info" do
    _cover_modules = Cover.compile(PathReader.expand_path(@beam_file_path))

    cover_modules = Cover.modules(PathReader.expand_path(@source_file_path))

    assert(
      Stats.calculate_stats(cover_modules, "/private/tmp/hello") ==
        @calculate_stats_with_path
    )

    pre_calculated_stats = Stats.calculate_stats(cover_modules, "/private/tmp/hello")

    assert(pre_calculated_stats == @calculate_stats_with_path)

    generate_coverage =
      Stats.generate_coverage(pre_calculated_stats, @source_code_project_base_path)

    assert(generate_coverage == @module_line_cover_stats)

    generate_coverage =
      Stats.generate_source_info(generate_coverage, @source_code_project_base_path)

    assert(generate_coverage == @module_source_info)

    Cover.stop()
  end
end

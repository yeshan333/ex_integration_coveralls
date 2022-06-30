defmodule ExIntegrationCoverallsTest do
  use ExUnit.Case
  import Mock
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader
  alias ExIntegrationCoveralls.CoverageCiPoster

  @project_realitive_dir "test/fixtures/hello"
  @application_dir PathReader.expand_path(@project_realitive_dir)
  @application_beam_dir PathReader.expand_path(@project_realitive_dir <> "/ebin")
  @compile_time_source_lib_abs_path "/private/tmp/hello"
  @run_time_env_cov_path {@application_dir, @compile_time_source_lib_abs_path,
                          @application_beam_dir}
  @cov_stats [{"lib/foo.ex", [nil, 0, nil, 0, nil, 1]}, {"lib/bar.ex", [1, 0, nil, 3, nil, 1]}]
  @cov_stats_map %{
    "lib/bar.ex" => %{1 => 1, 2 => 0, 3 => 0, 4 => 3, 5 => 0, 6 => 1},
    "lib/foo.ex" => %{1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 1}
  }
  @extends_params %{
    client: %{
      product: "explore_ast_app",
      group: "yeshan333",
      instance: "GitHub"
    },
    repository: %{
      projectName: "yeshan333/explore_ast_app",
      branch: "main",
      commitId: "e00aa95125061644d54afc5f6fc3b90aed1dfba0"
    }
  }
  @transform_stats Map.put(@extends_params, :files, @cov_stats_map)
  @response %HTTPoison.Response{
    body: "{\n  \"args\": {},\n  \"headers\": {} ...",
    headers: [
      {"Connection", "keep-alive"},
      {"Server", "Cowboy"},
      {"Date", "Sat, 25 Jun 2022 14:56:07 GMT"},
      {"Content-Length", "495"},
      {"Content-Type", "application/json"},
      {"Via", "1.1 vegur"}
    ],
    status_code: 200
  }

  @stats_report [
    %{
      coverage: [0, 1, nil, nil],
      name: "lib/hello.ex",
      source: "defmodule Test do\\n  def test do\\n  end\\nend"
    }
  ]
  @source_transform_cov_result %{
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

  test "start app cov" do
    with_mocks([
      {PathReader, [], [get_app_cover_path: fn _ -> @run_time_env_cov_path end]},
      {Cover, [], [compile: fn _ -> [ok: Hello] end]}
    ]) do
      result = ExIntegrationCoveralls.start_app_cov("hello")
      assert(result == [ok: Hello])
    end
  end

  test "get app total cov" do
    with_mocks([
      {PathReader, [], [get_app_cover_path: fn _ -> @run_time_env_cov_path end]},
      {Stats, [],
       [
         transform_cov: fn _ -> @source_transform_cov_result end,
         report: fn _, _, _ -> @stats_report end
       ]}
    ]) do
      assert(ExIntegrationCoveralls.get_app_total_cov("hello") == 50)
    end
  end

  test "post app total cov" do
    with_mocks([
      {PathReader, [], [get_app_cover_path: fn _ -> @run_time_env_cov_path end]},
      {Stats, [],
       [
         transform_cov: fn _ -> @source_transform_cov_result end,
         report: fn _, _, _ -> @stats_report end
       ]},
      {CoverageCiPoster, [],
       [
         get_coverage_stats: fn _, _ -> @cov_stats end,
         stats_transformer: fn _, _ -> @transform_stats end,
         post_stats_to_cover_ci: fn _, _, _, _ -> @response end
       ]}
    ]) do
      url = "https://github.com"

      assert(
        ExIntegrationCoveralls.post_app_cov_to_ci(url, @extends_params, "hello") == @response
      )
    end
  end

  test_with_mock "execute coverage", Cover, compile: fn _ -> [ok: Bar] end do
    assert(ExIntegrationCoveralls.execute("fake/beams/path") == [ok: Bar])
  end

  test_with_mock "stop cover", Cover, stop: fn -> :ok end do
    assert(ExIntegrationCoveralls.exit() == :ok)
  end

  test_with_mock "reset coverage data", Cover, reset: fn -> :ok end do
    assert(ExIntegrationCoveralls.reset_coverage_data() == :ok)
  end

  test_with_mock "get total coverage rate", Stats,
    report: fn _, _, _ -> @stats_report end,
    transform_cov: fn _ -> @source_transform_cov_result end do
    assert(ExIntegrationCoveralls.get_total_coverage() == 50)
  end

  test_with_mock "get total coverage analysis report", Stats,
    report: fn _, _, _ -> @stats_report end,
    transform_cov: fn _ -> @source_transform_cov_result end do
    assert(ExIntegrationCoveralls.get_coverage_report() == @source_transform_cov_result)
  end
end

defmodule ExIntegrationCoveralls.CoverageCiPosterTest do
  use ExUnit.Case, async: false
  import Mock
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.PathReader
  alias ExIntegrationCoveralls.CoverageCiPoster

  @compile_time_source_lib_abs_path PathReader.expand_path("lib/hello.ex", "/private/tmp/hello")
  @source_code_abs_path PathReader.expand_path("lib/hello.ex")
  @calc_stats %{"lib/hello.ex" => %{1 => 0, 4 => 0, 5 => 1}}
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

  test_with_mock "get coverage stats", Stats,
    calculate_stats: fn _, _ -> @calc_stats end,
    generate_coverage: fn _, _ -> @cov_stats end do
    assert(
      CoverageCiPoster.get_coverage_stats(
        @compile_time_source_lib_abs_path,
        @source_code_abs_path
      ) == @cov_stats
    )
  end

  test "stats transformer" do
    assert(CoverageCiPoster.stats_transformer(@cov_stats, @extends_params) == @transform_stats)
  end

  test_with_mock "post stats to cover ci service", CoverageCiPoster,
    get_coverage_stats: fn _, _ -> @cov_stats end,
    stats_transformer: fn _, _ -> @transform_stats end,
    post_stats_to_cover_ci: fn _, _, _, _ -> @response end do
    url = "https://github.com"

    assert(
      CoverageCiPoster.post_stats_to_cover_ci(
        url,
        @extends_params,
        @compile_time_source_lib_abs_path,
        @source_code_abs_path
      ) == @response
    )
  end
end

defmodule ExIntegrationCoveralls.PosterTest do
  use ExUnit.Case, async: false
  import Mock
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Json
  alias ExIntegrationCoveralls.Poster

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

  test_with_mock "post stats json data", HTTPoison, post: fn _, _, _, _ -> @response end do
    url = "https://github.com"
    body = Json.generate_json_output(@source_transform_cov_result)
    assert(Poster.post_to_coverage_services_center(url, body) == @response)
  end
end

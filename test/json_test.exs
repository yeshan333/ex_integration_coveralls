defmodule ExIntegrationCoveralls.JsonTest do
  use ExUnit.Case, async: false
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Json

  @counts [0, 1, nil, nil]
  @trimmed "defmodule Test do\n  def test do\n  end\nend"
  @source_info [
    %{name: "test/fixtures/test.ex", source: @trimmed, coverage: @counts}
  ]
  @json_source_info "[{\"source\":\"defmodule Test do\\n  def test do\\n  end\\nend\",\"name\":\"test/fixtures/test.ex\",\"coverage\":[0,1,null,null]}]"
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
  @json_source_transform_cov_result "{\"sloc\":2,\"misses\":1,\"hits\":1,\"files\":[{\"source\":[{\"source\":\"defmodule Test do\",\"coverage\":0},{\"source\":\"  def test do\",\"coverage\":1},{\"source\":\"  end\",\"coverage\":null},{\"source\":\"end\",\"coverage\":null}],\"sloc\":2,\"misses\":1,\"hits\":1,\"filename\":\"test/fixtures/test.ex\",\"coverage\":50}],\"coverage\":50}"

  test "json output - source info" do
    assert(Json.generate_json_output(@source_info) == @json_source_info)
  end

  test "json output - transform cov result" do
    assert(
      Json.generate_json_output(@source_transform_cov_result) == @json_source_transform_cov_result
    )
  end
end

defmodule ExIntegrationCoverallsTest do
  use ExUnit.Case
  import Mock
  alias ExIntegrationCoveralls.Stats
  alias ExIntegrationCoveralls.Cover

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

  test_with_mock "execute coverage", Cover, compile: fn _ -> [ok: Bar] end do
    assert ExIntegrationCoveralls.execute("fake/beams/path") == [ok: Bar]
  end

  test_with_mock "stop cover", Cover, stop: fn -> :ok end do
    assert ExIntegrationCoveralls.exit() == :ok
  end

  test_with_mock "reset coverage data ", Cover, reset: fn -> :ok end do
    assert ExIntegrationCoveralls.reset_coverage_data() == :ok
  end

  test_with_mock "get total coverage rate", Stats,
    report: fn _, _, _ -> @stats_report end,
    transform_cov: fn _ -> @source_transform_cov_result end do
    assert ExIntegrationCoveralls.get_total_coverage() == 50
  end

  test_with_mock "get total coverage analysis report", Stats,
    report: fn _, _, _ -> @stats_report end,
    transform_cov: fn _ -> @source_transform_cov_result end do
    assert ExIntegrationCoveralls.get_coverage_report() == @source_transform_cov_result
  end
end

defmodule ExIntegrationCoverallsTest do
  use ExUnit.Case
  doctest ExIntegrationCoveralls

  test "get integration total coverage" do
    assert ExIntegrationCoveralls.total_coverage() == 0
  end
end

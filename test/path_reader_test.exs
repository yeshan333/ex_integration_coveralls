defmodule ExIntegrationCoveralls.PathReaderTest do
  use ExUnit.Case, async: true
  alias ExIntegrationCoveralls.PathReader

  test "gets working directory base path" do
    assert(PathReader.base_path() == File.cwd!())
  end

  test "expand path" do
    assert(PathReader.expand_path("test") == File.cwd!() <> "/test")
  end
end

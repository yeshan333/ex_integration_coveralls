defmodule ExIntegrationCoveralls.PathReaderTest do
  use ExUnit.Case, async: true
  import Mock
  alias ExIntegrationCoveralls.PathReader

  @application_dir "test/fixtures/hello"

  test "gets working directory base path" do
    assert(PathReader.base_path() == File.cwd!())
  end

  test "expand path" do
    assert(PathReader.expand_path("test") == File.cwd!() <> "/test")
    assert(PathReader.expand_path("test", File.cwd!()) == File.cwd!() <> "/test")
  end

  test_with_mock "get app cover path", Application, app_dir: fn _  -> PathReader.expand_path(@application_dir) end do
    { run_time_source_lib_abs_path , compile_time_source_lib_abs_path } = PathReader.get_app_cover_path("ex_integration_coveralls")

    assert(run_time_source_lib_abs_path == PathReader.expand_path("test/fixtures/hello"))
    assert(compile_time_source_lib_abs_path == "/private/tmp/hello")
  end
end

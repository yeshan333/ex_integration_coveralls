defmodule ExIntegrationCoveralls.CoverTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader

  test "start module beam files stub" do
    cover_module_stub_list = [ok: Hello]

    assert(
      Cover.compile(PathReader.expand_path("test/fixtures/beams/hello_ebin")) ==
        cover_module_stub_list
    )

    Cover.stop()
  end

  test "stop cover server" do
    assert(Cover.stop() == :ok)
  end

  test "module path returns relative path for working directory" do
    assert(Cover.module_path(ExIntegrationCoveralls) == "lib/ex_integration_coveralls.ex")
    Cover.stop()
  end

  test "get cover modules" do
    _cover_modules = Cover.compile(PathReader.expand_path("test/fixtures/beams/hello_ebin"))
    assert(Cover.modules() == [Hello])
    Cover.stop()
  end

  test "get cover analyst, not compiled module by cover" do
    expect = {:error, {:not_cover_compiled, TestMissing}}
    assert(Cover.analyze(TestMissing) == expect)
  end

  test "get cover analyst, compiled module by cover" do
    _cover_modules = Cover.compile(PathReader.expand_path("test/fixtures/beams/hello_ebin"))

    expect =
      {:ok,
       [
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 0}, 0},
         {{Hello, 16}, 0},
         {{Hello, 18}, 0},
         {{Hello, 20}, 0}
       ]}

    assert(Cover.analyze(Hello) == expect)
  end

  test "has_compile_info?/1 with uncompiled module raises warning and returns false" do
    assert capture_io(:stderr, fn ->
             refute Cover.has_compile_info?(Foo)
           end) =~
             "[warning] skipping the module 'Elixir.Foo' because source information for the module is not available."
  end

  test "has_compile_info?/1 with missing source file raises warning and returns false" do
    assert Cover.has_compile_info?(TestMissing)

    path = Cover.module_path(TestMissing)
    backup_path = "test/fixtures/test_missing.bkp"

    on_exit({:clean_up, backup_path}, fn ->
      File.copy!(backup_path, path)
      File.rm!(backup_path)
    end)

    File.copy!(path, backup_path)
    File.rm!(path)
    refute File.exists?(path)

    assert capture_io(:stderr, fn ->
             refute Cover.has_compile_info?(TestMissing)
           end) =~
             "[warning] skipping the module 'Elixir.TestMissing' because source information for the module is not available."
  end

  test "has_compile_info?/1 with a mocked module raises warning and returns false" do
    :ok = :meck.new(MockedModule, [:non_strict])

    assert capture_io(:stderr, fn ->
             refute Cover.has_compile_info?(MockedModule)
           end) =~
             "[warning] skipping the module 'Elixir.MockedModule' because source information for the module is not available."
  end

  test "has_compile_info?/1 with existing source returns true" do
    assert Cover.has_compile_info?(TestMissing)
  end
end

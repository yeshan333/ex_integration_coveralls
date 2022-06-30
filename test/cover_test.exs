defmodule ExIntegrationCoveralls.CoverTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader

  @source_file_path "test/fixtures/hello/lib/hello.ex"
  @beam_file_path "test/fixtures/hello/ebin"

  @tag :real_cover
  test "start module beam ast code stub" do
    cover_module_stub_list = [ok: Hello]

    assert(
      Cover.compile(PathReader.expand_path(@beam_file_path)) ==
        cover_module_stub_list
    )

    Cover.stop()
  end

  @tag :real_cover
  test "stop cover server" do
    assert(Cover.stop() == :ok)
  end

  @tag :real_cover
  test "reset coverage data" do
    assert(Cover.reset() == :ok)
  end

  test "module path returns relative path for working directory" do
    assert(Cover.module_path(ExIntegrationCoveralls) == "lib/ex_integration_coveralls.ex")
  end

  test "module path returns relative path for given path" do
    assert(
      Cover.module_path(ExIntegrationCoveralls, ExIntegrationCoveralls.PathReader.base_path()) ==
        "lib/ex_integration_coveralls.ex"
    )
  end

  @tag :real_cover
  test "get cover modules" do
    _cover_modules = Cover.compile(PathReader.expand_path(@beam_file_path))

    assert(
      Cover.modules(
        ExIntegrationCoveralls.PathReader.base_path() <>
          "/" <>
          @source_file_path
      ) == [Hello]
    )

    Cover.stop()
  end

  @tag :real_cover
  test "get cover modules (no source_lib_absolute_path param)" do
    _cover_modules = Cover.compile(PathReader.expand_path(@beam_file_path))

    assert(
      capture_io(:stderr, fn ->
        assert(Cover.modules() == [])
      end) =~
        "[warning] skipping the module 'Elixir.Hello' because source information for the module is not available."
    )

    Cover.stop()
  end

  test "get cover analyst, not compiled module by cover" do
    expect = {:error, {:not_cover_compiled, Foo}}
    assert Cover.analyze(Foo) == expect
  end

  @tag :real_cover
  test "get cover analyst, compiled module by cover" do
    _cover_modules = Cover.compile(PathReader.expand_path(@beam_file_path))

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
    assert(
      capture_io(:stderr, fn ->
        refute Cover.has_compile_info?(Foo)
      end) =~
        "[warning] skipping the module 'Elixir.Foo' because source information for the module is not available."
    )
  end

  test "has_compile_info?/1 with missing source file raises warning and returns false" do
    assert(Cover.has_compile_info?(TestMissing))

    path = Cover.module_path(TestMissing)
    backup_path = "test/fixtures/test_missing.bkp"

    on_exit({:clean_up, backup_path}, fn ->
      File.copy!(backup_path, path)
      File.rm!(backup_path)
    end)

    File.copy!(path, backup_path)
    File.rm!(path)
    refute File.exists?(path)

    assert(
      capture_io(:stderr, fn ->
        refute Cover.has_compile_info?(TestMissing)
      end) =~
        "[warning] skipping the module 'Elixir.TestMissing' because source information for the module is not available."
    )
  end

  test "has_compile_info?/1 with a mocked module raises warning and returns false" do
    :ok = :meck.new(MockedModule, [:non_strict])

    assert(
      capture_io(:stderr, fn ->
        refute Cover.has_compile_info?(MockedModule)
      end) =~
        "[warning] skipping the module 'Elixir.MockedModule' because source information for the module is not available."
    )
  end

  test "has_compile_info?/1 with existing source returns true" do
    assert(Cover.has_compile_info?(TestMissing))
  end
end

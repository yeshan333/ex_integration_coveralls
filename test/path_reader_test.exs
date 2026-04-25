defmodule ExIntegrationCoveralls.PathReaderTest do
  use ExUnit.Case, async: false
  import Mock
  alias ExIntegrationCoveralls.PathReader

  @application_dir "test/fixtures/hello"
  @beam_debug_info {:ok,
                    {Hello,
                     [
                       debug_info:
                         {:debug_info_v1, :elixir_erl,
                          {:elixir_v1,
                           %{
                             attributes: [],
                             compile_opts: [],
                             definitions: [
                               {{:hello, 0}, :def, [line: 15],
                                [
                                  {[line: 15], [], [],
                                   {:__block__, [],
                                    [
                                      {{:., [line: 16], [File, :cwd!]}, [line: 16], []},
                                      :world,
                                      {{:., [line: 18], [File, :cwd!]}, [line: 18], []},
                                      :hello,
                                      {{:., [line: 20], [File, :cwd!]}, [line: 20], []},
                                      :world
                                    ]}}
                                ]}
                             ],
                             deprecated: [],
                             file: "/private/tmp/hello/lib/hello.ex",
                             is_behaviour: false,
                             line: 1,
                             module: Hello,
                             relative_file: "lib/hello.ex",
                             struct: nil,
                             unreachable: []
                           }, []}}
                     ]}}

  test "gets working directory base path" do
    assert(PathReader.base_path() == File.cwd!())
  end

  test "expand path" do
    assert(PathReader.expand_path("test") == File.cwd!() <> "/test")
    assert(PathReader.expand_path("test", File.cwd!()) == File.cwd!() <> "/test")
  end

  test "get app cover path" do
    # Use the real Application.app_dir and only mock :beam_lib to control compile-time path.
    # Mocking Application is unsafe because it's a core OTP module used by Logger, ExUnit, etc.
    app_dir = Application.app_dir(:ex_integration_coveralls)

    with_mock :beam_lib, [:unstick], chunks: fn _, _ -> @beam_debug_info end do
      {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, app_beam_dir} =
        PathReader.get_app_cover_path("ex_integration_coveralls")

      assert(run_time_source_lib_abs_path == app_dir)
      assert(compile_time_source_lib_abs_path == "/private/tmp/hello")
      assert(app_beam_dir == app_dir <> "/ebin")
    end
  end

  test "read commit id" do
    {commit_id, branch} =
      PathReader.get_commit_id_and_branch_from_file(
        PathReader.expand_path(@application_dir <> "/VERSION_INFO")
      )

    assert(commit_id == "702c1d15e59d87707dbd4676960238efc598f740")
    assert(branch == "main")
  end

  test "get apps cover paths returns list of tuples" do
    app_dir = Application.app_dir(:ex_integration_coveralls)

    with_mock :beam_lib, [:unstick], chunks: fn _, _ -> @beam_debug_info end do
      result =
        PathReader.get_apps_cover_paths([
          "ex_integration_coveralls",
          "ex_integration_coveralls"
        ])

      assert length(result) == 2

      Enum.each(result, fn {runtime, compile_time, beam_dir} ->
        assert runtime == app_dir
        assert compile_time == "/private/tmp/hello"
        assert beam_dir == app_dir <> "/ebin"
      end)
    end
  end
end

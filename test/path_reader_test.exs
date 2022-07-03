defmodule ExIntegrationCoveralls.PathReaderTest do
  use ExUnit.Case, async: true
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

  # test_with_mock "get app cover path", Application,
  #   app_dir: fn _ -> PathReader.expand_path(@application_dir) end do
  #   {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, app_beam_dir} =
  #     PathReader.get_app_cover_path("ex_integration_coveralls")

  #   assert(run_time_source_lib_abs_path == PathReader.expand_path("test/fixtures/hello"))
  #   assert(compile_time_source_lib_abs_path == "/private/tmp/hello")
  #   assert(app_beam_dir == PathReader.expand_path("test/fixtures/hello/ebin"))
  # end

  test "get app cover path" do
    with_mocks([
      {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]},
      {:beam_lib, [:unstick], [chunks: fn _, _ -> @beam_debug_info end]}
    ]) do
      {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, app_beam_dir} =
        PathReader.get_app_cover_path("ex_integration_coveralls")

      assert(run_time_source_lib_abs_path == PathReader.expand_path("test/fixtures/hello"))
      assert(compile_time_source_lib_abs_path == "/private/tmp/hello")
      assert(app_beam_dir == PathReader.expand_path("test/fixtures/hello/ebin"))
    end
  end

  test "read commit id" do
    commit_id =
      PathReader.get_commit_id_from_file(
        PathReader.expand_path(@application_dir <> "/VERSION_INFO")
      )

    assert(commit_id == "43a9595")
  end
end

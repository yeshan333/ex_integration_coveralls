defmodule ExIntegrationCoveralls.CovStatsRouterTest do
  use ExUnit.Case
  use Plug.Test
  import Mock

  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader
  alias ExIntegrationCoveralls.CovStatsRouter
  alias ExIntegrationCoveralls.CoverageCiPoster

  @opts CovStatsRouter.init([])
  @cov_stats %{"lib/bar.ex" => %{1 => 1, 2 => 0, 3 => 0, 4 => 3, 5 => 0, 6 => 1}}
  @transform_stats Map.put(%{}, :files, @cov_stats)
  @report "{\"files\":{\"lib/bar.ex\":{\"6\":1,\"5\":0,\"4\":3,\"3\":0,\"2\":0,\"1\":1}}}"
  @extends_params %{
    client: %{
      product: "explore_ast_app",
      group: "yeshan333",
      instance: "GitHub"
    },
    repository: %{
      projectName: "yeshan333/explore_ast_app",
      branch: "main",
      commitId: "e00aa95125061644d54afc5f6fc3b90aed1dfba0"
    }
  }
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
  @run_time_source_lib_abs_path PathReader.expand_path("test/fixtures/hello")
  @compile_time_source_lib_abs_path "/private/tmp/hello"
  @app_beam_dir PathReader.expand_path("test/fixtures/hello/ebin")
  @app_cover_path {@run_time_source_lib_abs_path, @compile_time_source_lib_abs_path,
                   @app_beam_dir}

  test "ping" do
    conn =
      :get
      |> conn("/ping", "")
      |> CovStatsRouter.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "pong!"
  end

  describe "cov start" do
    test "unkunow_app" do
      assert_raise Plug.Conn.WrapperError, fn ->
        :post
        |> conn("/cov/start", %{:app_name => "unkunow_app"})
        |> CovStatsRouter.call(@opts)
      end
    end

    test_with_mock "foo app", ExIntegrationCoveralls, start_app_cov: fn _ -> [ok: Foo] end do
      conn =
        :post
        |> conn("/cov/start", %{:app_name => "foo"})
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test_with_mock "foo app async", ExIntegrationCoveralls, start_app_cov: fn _ -> [ok: Foo] end do
      conn =
        :post
        |> conn("/cov/start", %{:app_name => "foo", :use_async => true})
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end
  end

  describe "total coverage" do
    test "unkunow_app" do
      assert_raise Plug.Conn.WrapperError, fn ->
        :get
        |> conn("/cov/total/unkunow_app", "")
        |> CovStatsRouter.call(@opts)
      end
    end

    test_with_mock "foo app total cov", ExIntegrationCoveralls, get_app_total_cov: fn _ -> 50 end do
      conn =
        :get
        |> conn("/cov/total/foo", "")
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"coverage\":50}"
    end
  end

  describe "cover server status" do
    test_with_mock "not_started", Cover, check_cover_status: fn -> :not_started end do
      conn =
        :get
        |> conn("/cov/status", "")
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"status\":\"not_started\"}"
    end

    test_with_mock "already_started", Cover, check_cover_status: fn -> :already_started end do
      conn =
        :get
        |> conn("/cov/status", "")
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"status\":\"already_started\"}"
    end
  end

  describe "cov report" do
    test "unkunow_app" do
      assert_raise Plug.Conn.WrapperError, fn ->
        :get
        |> conn("/cov/report/unkunow_app", "")
        |> CovStatsRouter.call(@opts)
      end
    end

    test "foo app cov report" do
      with_mocks([
        {CoverageCiPoster, [],
         [
           get_coverage_stats: fn _, _ -> @cov_stats end,
           stats_transformer: fn _ -> @transform_stats end
         ]},
        {PathReader, [],
         [get_app_cover_path: fn _ -> {"compile_path", "run_time_path", "app_dir"} end]}
      ]) do
        conn =
          :get
          |> conn("/cov/report/foo", "")
          |> CovStatsRouter.call(@opts)

        assert conn.state == :sent
        assert conn.status == 200
        assert conn.resp_body == @report
      end
    end
  end

  describe "cov push trigger" do
    test "bad request" do
      conn =
        :post
        |> conn("/cov/push_trigger", %{:app_name => "foo"})
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 400
    end

    test_with_mock "foo app", ExIntegrationCoveralls,
      post_app_cov_to_ci: fn _, _, _ -> @response end do
      url = "https://github.com"

      conn =
        :post
        |> conn("/cov/push_trigger", %{
          :app_name => "foo",
          :extend_params => @extends_params,
          :url => url
        })
        |> CovStatsRouter.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end
  end

  describe "get app commit id" do
    test "unkunow_app" do
      assert_raise Plug.Conn.WrapperError, fn ->
        :get
        |> conn("/cov/commit_id/unkunow_app", "")
        |> CovStatsRouter.call(@opts)
      end
    end

    test "foo app commit id and branch" do
      with_mocks([
        {PathReader, [],
         [
           get_app_cover_path: fn _ -> @app_cover_path end,
           expand_path: fn _, _ -> @run_time_source_lib_abs_path <> "/VERSION_INFO" end,
           get_commit_id_and_branch_from_file: fn _ ->
             {"702c1d15e59d87707dbd4676960238efc598f740", "main"}
           end
         ]}
      ]) do
        conn =
          :get
          |> conn("/cov/commit_id/foo", "")
          |> CovStatsRouter.call(@opts)

        assert conn.state == :sent
        assert conn.status == 200

        assert conn.resp_body |> Jason.decode!() ==
                 "{\"commit_id\":\"702c1d15e59d87707dbd4676960238efc598f740\",\"branch\":\"main\",\"app_name\":\"foo\"}" |> Jason.decode!()
      end
    end
  end

  test "unknown route" do
    conn =
      :get
      |> conn("/helloworld", "")
      |> CovStatsRouter.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "unknown route!"
  end
end

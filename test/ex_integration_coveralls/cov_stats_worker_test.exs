defmodule ExIntegrationCoveralls.CovStatsWorkerTest do
  use ExUnit.Case
  use Plug.Test
  import Mock
  alias ExIntegrationCoveralls.CovStatsWorker
  alias ExIntegrationCoveralls.PathReader

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
  @application_dir "test/fixtures/hello"

  setup_all do
    # String.to_atom("explore_ast_app")
    Application.start(:explore_ast_app, :permanent)
    :ok
  end

  setup do
    # Ensure the CovStatsWorker is running.
    # It may have crashed from async cast tests (router tests send casts
    # that are processed after mock teardown, crashing the GenServer).
    # If the supervisor exceeded max_restarts, the whole app shuts down.
    unless Process.whereis(CovStatsWorker) do
      Application.stop(:ex_integration_coveralls)
      Application.ensure_all_started(:ex_integration_coveralls)
    end

    :ok
  end

  describe "start app cov" do
    test "call" do
      with_mocks([
        {ExIntegrationCoveralls, [],
         [
           start_app_cov: fn _ -> [ok: Hello] end
         ]},
        {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
      ]) do
        pid = Process.whereis(CovStatsWorker)

        result = GenServer.call(pid, {:start_cov, "explore_ast_app"})
        assert(result == [ok: Hello])
      end
    end

    test "cast" do
      with_mocks([
        {ExIntegrationCoveralls, [],
         [
           start_app_cov: fn _ -> [ok: Hello] end
         ]},
        {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
      ]) do
        pid = Process.whereis(CovStatsWorker)

        result = GenServer.cast(pid, {:start_cov, "explore_ast_app"})
        assert(result == :ok)
      end
    end
  end

  test "stop app cov" do
    with_mocks([
      {ExIntegrationCoveralls, [],
       [
         exit: fn -> :ok end
       ]},
      {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
    ]) do
      pid = Process.whereis(CovStatsWorker)

      result = GenServer.call(pid, {:stop_cov})
      assert(result == :ok)
    end
  end

  test_with_mock "app cov push to coverage ci", ExIntegrationCoveralls,
    post_app_cov_to_ci: fn _, _, _, _ -> @response end do
    pid = Process.whereis(CovStatsWorker)

    app_name = "explore_ast_app"
    extend_params = %{}
    url = "https://github.com"

    result =
      GenServer.cast(
        pid,
        {:start_cov_push,
         %{"app_name" => app_name, "extend_params" => extend_params, "url" => url}}
      )

    assert(result == :ok)
  end

  describe "start app cov with dep_apps" do
    test "call with opts" do
      with_mocks([
        {ExIntegrationCoveralls, [],
         [
           start_app_cov: fn _, _ -> [ok: Hello, ok: Dep1] end
         ]},
        {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
      ]) do
        pid = Process.whereis(CovStatsWorker)

        result = GenServer.call(pid, {:start_cov, "explore_ast_app", [dep_apps: ["dep1"]]})
        assert(result == [ok: Hello, ok: Dep1])
      end
    end

    test "cast with opts" do
      with_mocks([
        {ExIntegrationCoveralls, [],
         [
           start_app_cov: fn _, _ -> [ok: Hello, ok: Dep1] end
         ]},
        {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
      ]) do
        pid = Process.whereis(CovStatsWorker)

        result = GenServer.cast(pid, {:start_cov, "explore_ast_app", [dep_apps: ["dep1"]]})
        assert(result == :ok)
      end
    end
  end

  test_with_mock "app cov push to coverage ci with dep_apps", ExIntegrationCoveralls,
    post_app_cov_to_ci: fn _, _, _, _ -> @response end do
    pid = Process.whereis(CovStatsWorker)

    app_name = "explore_ast_app"
    extend_params = %{}
    url = "https://github.com"

    result =
      GenServer.cast(
        pid,
        {:start_cov_push,
         %{
           "app_name" => app_name,
           "extend_params" => extend_params,
           "url" => url,
           "dep_apps" => ["dep1"]
         }}
      )

    assert(result == :ok)
  end
end

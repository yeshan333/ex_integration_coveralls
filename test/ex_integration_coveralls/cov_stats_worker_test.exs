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
        exit: fn -> :ok  end
       ]},
       {Application, [], [app_dir: fn _ -> PathReader.expand_path(@application_dir) end]}
    ]) do
      pid = Process.whereis(CovStatsWorker)

      result = GenServer.call(pid, {:stop_cov})
      assert(result == :ok)
    end
  end

  test_with_mock "app cov push to coverage ci", ExIntegrationCoveralls,
    post_app_cov_to_ci: fn _, _, _ -> @response end do
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
end

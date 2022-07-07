defmodule ExIntegrationCoveralls.CovStatsWorkerTest do
  use ExUnit.Case
  use Plug.Test
  import Mock
  alias ExIntegrationCoveralls.CovStatsWorker

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

  describe "start app cov" do
    test_with_mock "call", ExIntegrationCoveralls, start_app_cov: fn _ -> [ok: Hello] end do
      {:ok, pid} = CovStatsWorker.start_link()

      result = GenServer.call(pid, {:start_cov, "explore_ast_app"})
      assert(result == [ok: Hello])
    end

    test_with_mock "cast", ExIntegrationCoveralls, start_app_cov: fn _ -> [ok: Hello] end do
      {:ok, pid} = CovStatsWorker.start_link()

      result = GenServer.cast(pid, {:start_cov, "explore_ast_app"})
      assert(result == :ok)
    end
  end

  test_with_mock "stop app cov", ExIntegrationCoveralls, exit: fn  -> :ok end do
    {:ok, pid} = CovStatsWorker.start_link()

    result = GenServer.call(pid, {:stop_cov})
    assert(result == :ok)
  end

  test_with_mock "app cov push to coverage ci", ExIntegrationCoveralls, post_app_cov_to_ci: fn _, _, _ -> @response end do
    {:ok, pid} = CovStatsWorker.start_link()

    app_name = "explore_ast_app"
    extend_params = %{}
    url = "https://github.com"
    result = GenServer.cast(pid, {:start_cov_push, %{"app_name" => app_name, "extend_params" => extend_params, "url" => url}})
    assert(result == :ok)
  end
end

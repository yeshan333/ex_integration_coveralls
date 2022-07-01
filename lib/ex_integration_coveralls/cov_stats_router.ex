defmodule ExIntegrationCoveralls.CovStatsRouter do
  use Plug.Router
  alias ExIntegrationCoveralls.Json
  alias ExIntegrationCoveralls.PathReader
  alias ExIntegrationCoveralls.CoverageCiPoster

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  post "/cov/start" do
    {status, _} =
      case conn.body_params do
        %{"app_name" => app_name} -> {200, ExIntegrationCoveralls.start_app_cov(app_name)}
        _ -> {400, "bad request!"}
      end

    send_resp(conn, status, "OK")
  end

  get "/cov/total/:app_name" do
    total_cov = ExIntegrationCoveralls.get_app_total_cov(app_name)

    body =
      Json.generate_json_output(%{
        coverage: total_cov
      })

    send_resp(conn, 200, body)
  end

  get "/cov/report/:app_name" do
    {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, _} =
      PathReader.get_app_cover_path(app_name)

    stats =
      CoverageCiPoster.get_coverage_stats(
        compile_time_source_lib_abs_path,
        run_time_source_lib_abs_path
      )
      |> CoverageCiPoster.stats_transformer()

    body = Json.generate_json_output(stats)
    send_resp(conn, 200, body)
  end

  match _ do
    send_resp(conn, 404, "unknown route!")
  end
end

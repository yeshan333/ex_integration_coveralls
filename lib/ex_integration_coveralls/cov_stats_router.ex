defmodule ExIntegrationCoveralls.CovStatsRouter do
  use Plug.Router
  require Logger

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  get "/stats" do
    stats = ExIntegrationCoveralls.get_app_total_cov("explore_ast_app")
    stats_json = ExIntegrationCoveralls.Json.generate_json_output(%{
      coverage: stats
    })
    Logger.warn("stats: #{inspect(stats)}, resp #{stats_json}")
    send_resp(conn, 200, stats_json)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

defmodule ExIntegrationCoveralls.CovStatsRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/stats" do
    stats = ExIntegrationCoveralls.get_app_total_cov("explore_ast_app")
    resp = ExIntegrationCoveralls.Json.generate_json_output(%{
      coverage: stats
    })
    send_resp(conn, 200, resp)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

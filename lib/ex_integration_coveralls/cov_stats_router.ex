defmodule ExIntegrationCoveralls.CovStatsRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/stats" do
    resp = ExIntegrationCoveralls.get_app_total_cov("explore_ast_app")
    send_resp(conn, 200, resp)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

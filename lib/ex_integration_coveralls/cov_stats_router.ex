defmodule ExIntegrationCoveralls.CovStatsRouter do
  @moduledoc """
  Expose coverage stats by http endpoints.
  """
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

  # Used to trigger push coverage data to coverage system.
  post "/cov/push_trigger" do
    {status, _} =
      case conn.body_params do
        %{"app_name" => app_name, "extend_params" => extend_params, "url" => url} ->
          {200, ExIntegrationCoveralls.post_app_cov_to_ci(url, extend_params, app_name)}

        _ ->
          {400, "bad request!"}
      end

    send_resp(conn, status, "OK")
  end

  # User-defined, get commit to diff coverage data, compare with previous coverage
  get "/cov/commit_id/:app_name" do
    ## Hard Code ##
    {run_time_source_lib_abs_path, _, _} = PathReader.get_app_cover_path(app_name)
    # the path include app commit id info.
    # format like this:
    # TAG=hello-202210091408, APP_RELEASE_VERSION=hello-202210091408-43a9595, PUSHER=yeshan333, PACKAGE=yeshan333/hello/hello-202210091408-43a9595.tar.gz
    commit_id =
      PathReader.get_commit_id_from_file(
        PathReader.expand_path("../../VERSION_INFO", run_time_source_lib_abs_path)
      )

    ## Hard Code ##
    body =
      Json.generate_json_output(%{
        app_name: app_name,
        commit_id: commit_id
      })

    send_resp(conn, 200, body)
  end

  match _ do
    send_resp(conn, 404, "unknown route!")
  end
end

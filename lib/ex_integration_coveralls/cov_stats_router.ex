defmodule ExIntegrationCoveralls.CovStatsRouter do
  @moduledoc """
  Expose coverage stats by http endpoints.
  """
  use Plug.Router
  alias ExIntegrationCoveralls.Json
  alias ExIntegrationCoveralls.Cover
  alias ExIntegrationCoveralls.PathReader
  alias ExIntegrationCoveralls.CoverageCiPoster
  alias ExIntegrationCoveralls.CovStatsWorker

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  post "/cov/start" do
    {status, _} =
      case conn.body_params do
        %{"app_name" => app_name} ->
          use_async = Map.get(conn.body_params, "use_async", false)
          dep_apps = Map.get(conn.body_params, "dep_apps", [])
          opts = build_opts(dep_apps)

          case use_async do
            true -> {200, GenServer.cast(CovStatsWorker, {:start_cov, app_name, opts})}
            _ -> {200, ExIntegrationCoveralls.start_app_cov(app_name, opts)}
          end

        _ ->
          {400, "bad request!"}
      end

    send_resp(conn, status, "OK")
  end

  get "/cov/total/:app_name" do
    conn = Plug.Conn.fetch_query_params(conn)
    dep_apps = parse_dep_apps_query(conn)
    source_dir = parse_source_dir_query(conn)
    opts = build_opts(dep_apps)

    total_cov =
      case {dep_apps, source_dir} do
        {[], source_dir} when not is_nil(source_dir) ->
          {_, compile_time_source_lib_abs_path, _} = PathReader.get_app_cover_path(app_name)
          ExIntegrationCoveralls.get_total_coverage(compile_time_source_lib_abs_path, source_dir)

        _ ->
          ExIntegrationCoveralls.get_app_total_cov(app_name, opts)
      end

    body =
      Json.generate_json_output(%{
        coverage: total_cov
      })

    send_resp(conn, 200, body)
  end

  get "/cov/status" do
    status = Cover.check_cover_status()

    body =
      Json.generate_json_output(%{
        status: status
      })

    send_resp(conn, 200, body)
  end

  get "/cov/report/:app_name" do
    conn = Plug.Conn.fetch_query_params(conn)
    dep_apps = parse_dep_apps_query(conn)
    source_dir = parse_source_dir_query(conn)

    stats =
      case dep_apps do
        [] ->
          {run_time_source_lib_abs_path, compile_time_source_lib_abs_path, _} =
            PathReader.get_app_cover_path(app_name)

          effective_runtime_path = source_dir || run_time_source_lib_abs_path

          CoverageCiPoster.get_coverage_stats(
            compile_time_source_lib_abs_path,
            effective_runtime_path
          )
          |> CoverageCiPoster.stats_transformer()

        dep_apps when is_list(dep_apps) ->
          all_app_names = [app_name | dep_apps]
          all_paths = PathReader.get_apps_cover_paths(all_app_names)

          path_pairs =
            Enum.map(all_paths, fn {runtime, compile_time, _} -> {compile_time, runtime} end)

          CoverageCiPoster.get_coverage_stats_multi(path_pairs)
          |> CoverageCiPoster.stats_transformer()
      end

    body = Json.generate_json_output(stats)
    send_resp(conn, 200, body)
  end

  # Used to trigger push coverage data to coverage system.
  post "/cov/push_trigger" do
    {status, _} =
      case conn.body_params do
        %{"app_name" => app_name, "extend_params" => extend_params, "url" => url} ->
          dep_apps = Map.get(conn.body_params, "dep_apps", [])
          opts = build_opts(dep_apps)
          {200, ExIntegrationCoveralls.post_app_cov_to_ci(url, extend_params, app_name, opts)}

        _ ->
          {400, "bad request!"}
      end

    send_resp(conn, status, "OK")
  end

  # User-defined, get commit to diff coverage data, compare with previous coverage.
  # You can use it to calculate incremental coverage.
  get "/cov/commit_id/:app_name" do
    ## Hard Code ##
    {run_time_source_lib_abs_path, _, _} = PathReader.get_app_cover_path(app_name)
    # the path include app commit id info.
    # format like this:
    # TAG=hello-202210091408, APP_RELEASE_VERSION=hello-202210091408-43a9595, PUSHER=yeshan333, PACKAGE=yeshan333/hello/hello-202210091408-43a9595.tar.gz
    {commit_id, branch} =
      PathReader.get_commit_id_and_branch_from_file(
        PathReader.expand_path("../../VERSION_INFO", run_time_source_lib_abs_path)
      )

    ## Hard Code ##
    body =
      Json.generate_json_output(%{
        app_name: app_name,
        commit_id: commit_id,
        branch: branch
      })

    send_resp(conn, 200, body)
  end

  match _ do
    send_resp(conn, 404, "unknown route!")
  end

  defp parse_dep_apps_query(conn) do
    case conn.query_params do
      %{"dep_apps" => dep_apps_str} when is_binary(dep_apps_str) ->
        dep_apps_str |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

      _ ->
        []
    end
  end

  defp parse_source_dir_query(conn) do
    case conn.query_params do
      %{"source_dir" => source_dir} when is_binary(source_dir) and source_dir != "" ->
        source_dir

      _ ->
        nil
    end
  end

  defp build_opts([]), do: []
  defp build_opts(dep_apps) when is_list(dep_apps), do: [dep_apps: dep_apps]
end

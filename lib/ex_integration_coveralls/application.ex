defmodule ExIntegrationCoveralls.Application do
  @moduledoc """
  Start a http worker to expose coverage stats.
  """

  use Application
  alias ExIntegrationCoveralls.CovStatsRouter
  alias ExIntegrationCoveralls.CovStatsWorker

  def start(_type, _args) do
    children =
      [
        start_http_cov_worker()
      ] ++ start_cov_worker()

    opts = [strategy: :one_for_one, name: ExIntegrationCoveralls.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_http_cov_worker do
    http_cfg =
      Application.get_env(:cov_worker, :http, %{
        listen_ip: {0, 0, 0, 0},
        listen_port: 3333
      })

    cowboy_options = [
      port: http_cfg.listen_port,
      ip: http_cfg.listen_ip
    ]

    Plug.Cowboy.child_spec(
      scheme: :http,
      plug: CovStatsRouter,
      options: cowboy_options
    )
  end

  defp start_cov_worker() do
    case is_use_cov_worker?() do
      true ->
        [
          %{
            id: CovStatsWorker,
            start: {CovStatsWorker, :start_link, []},
            type: :worker
          }
        ]

      _false ->
        []
    end
  end

  def is_use_cov_worker?() do
    Application.get_env(:cov_worker, :enable_cov_worker, true)
  end
end

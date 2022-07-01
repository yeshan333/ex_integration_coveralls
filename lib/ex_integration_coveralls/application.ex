defmodule ExIntegrationCoveralls.Application do
  @moduledoc """

  """

  use Application
  alias ExIntegrationCoveralls.CovStatsRouter

  def start(_type, _args) do
    children = [
      start_http_worker()
    ]

    opts = [strategy: :one_for_one, name: ExIntegrationCoveralls.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_http_worker do
    http_cfg =
      Application.get_env(:cov_worker, :http, %{
        listen_ip: {0, 0, 0, 0},
        listen_port: 3333
      })

    cowboy_optsions = [
      port: http_cfg.listen_port,
      ip: http_cfg.listen_ip
    ]

    Plug.Cowboy.child_spec(
      scheme: :http,
      plug: CovStatsRouter,
      options: cowboy_optsions
    )
  end
end

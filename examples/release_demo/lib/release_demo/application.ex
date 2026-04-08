defmodule ReleaseDemo.Application do
  @moduledoc """
  Application module that starts the supervision tree.

  The ex_integration_coveralls dependency auto-starts its own HTTP server
  (default port 3333) and CovStatsWorker via its own Application module.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: ReleaseDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

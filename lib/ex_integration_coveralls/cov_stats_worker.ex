defmodule ExIntegrationCoveralls.CovStatsWorker do
  @moduledoc false
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{app_name: ""}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:start_cov, app_name}, _from, state) do
    result = ExIntegrationCoveralls.start_app_cov(app_name)
    {:reply, result, Map.put(state, :app_name, app_name)}
  end

  @impl true
  def handle_call({:stop_cov}, _from, state) do
    status = ExIntegrationCoveralls.exit()
    {:reply, status, state}
  end

  @impl true
  def handle_cast({:start_cov, app_name}, state) do
    ExIntegrationCoveralls.start_app_cov(app_name)
    {:noreply, Map.put(state, :app_name, app_name)}
  end

  @impl true
  def handle_cast({:start_cov_push, %{"app_name" => app_name, "extend_params" => extend_params, "url" => url} = state}, state) do
    ExIntegrationCoveralls.post_app_cov_to_ci(url, extend_params, app_name)
    {:reply, Map.put(state, :app_name, app_name)}
  end
end

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
  def handle_call({:start_cov, app_name, opts}, _from, state) do
    result = ExIntegrationCoveralls.start_app_cov(app_name, opts)
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
  rescue
    e ->
      require Logger
      Logger.error("CovStatsWorker start_cov failed: #{inspect(e)}")
      {:noreply, state}
  end

  @impl true
  def handle_cast({:start_cov, app_name, opts}, state) do
    ExIntegrationCoveralls.start_app_cov(app_name, opts)
    {:noreply, Map.put(state, :app_name, app_name)}
  rescue
    e ->
      require Logger
      Logger.error("CovStatsWorker start_cov failed: #{inspect(e)}")
      {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:start_cov_push,
         %{"app_name" => app_name, "extend_params" => extend_params, "url" => url} = params},
        state
      ) do
    dep_apps = Map.get(params, "dep_apps", [])
    opts = if dep_apps == [], do: [], else: [dep_apps: dep_apps]
    ExIntegrationCoveralls.post_app_cov_to_ci(url, extend_params, app_name, opts)
    {:noreply, Map.put(state, :app_name, app_name)}
  rescue
    e ->
      require Logger
      Logger.error("CovStatsWorker start_cov_push failed: #{inspect(e)}")
      {:noreply, state}
  end
end

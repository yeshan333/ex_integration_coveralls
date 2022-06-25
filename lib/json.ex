defmodule ExIntegrationCoveralls.Json do
  @moduledoc """
  Serialize the coverage data to human-readable json format.
  """

  @doc """
  Dumps stats to json
  ## Parameters
  - stats: coverage data
  """
  def generate_json_output(stats) do
    Poison.encode!(stats)
  end
end

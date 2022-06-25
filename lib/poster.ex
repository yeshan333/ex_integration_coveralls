defmodule ExIntegrationCoveralls.Poster do
  @moduledoc """
  General handler for posting coverage data to CI Services.
  """

  @doc """
  Http poster.

  ## Parameters
  - url: remote coverage CI Services URL
  - body: a json string which be Posion encoded
  - headers: use to extend http headers
  """
  def post_to_coverage_services_center(url, body, headers \\ []) do
    httposion_headers = [{"Content-type", "application/json"}] ++ headers
    HTTPoison.post(url, body, httposion_headers, [])
  end
end

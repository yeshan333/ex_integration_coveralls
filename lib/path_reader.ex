defmodule ExIntegrationCoveralls.PathReader do
  @moduledoc """
  Provide methods for base path for displaying File paths of the modules.
  It uses the current working directory.
  """

  @doc """
  Returns the current working directory.
  """
  def base_path do
    File.cwd!()
  end

  @doc """
  Expand path relative to the base_path.
  """
  def expand_path(path, base_path \\ base_path()) do
    Path.expand(path, base_path)
  end
end

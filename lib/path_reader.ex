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

  @doc """
  Get application cover path.

  ## Parameters
  - appname: application name in run-time environment. It is a string
  """
  def get_app_cover_path(appname) do
    app_dir = Application.app_dir(String.to_existing_atom(appname))
    app_beam_dir = app_dir <> "/ebin"

    beam_file_path_list = File.ls!(app_beam_dir)
    beam_file_path = List.first(beam_file_path_list)
    beam_file_abs_path = app_beam_dir <> "/" <> beam_file_path

    {:ok, {_, [debug_info]}} =
      :beam_lib.chunks(String.to_charlist(beam_file_abs_path), [:debug_info])

    {:debug_info, {:debug_info_v1, :elixir_erl, {:elixir_v1, compile_time_info, _}}} = debug_info
    spliter = Map.get(compile_time_info, :relative_file)
    compile_time_abs_path = Map.get(compile_time_info, :file)

    compile_time_source_lib_abs_path =
      List.first(String.split(compile_time_abs_path, "/" <> spliter))

    {app_dir, compile_time_source_lib_abs_path, app_beam_dir}
  end

  @doc """
  Get git commit id. Can be used to compare with previous coverage results (last commit).
  """
  def get_commit_id_and_branch_from_file(path) do
    {:ok, content} = File.read(path)
    [_tag, _app_rel_vsn, _pusher, _package, source_branch, full_commit_id] = String.split(content, ", ")
    commit_id = String.split(full_commit_id, "=") |> List.last() |> String.trim()
    branch = String.split(source_branch, "=") |> List.last() |> String.trim()
    {commit_id, branch}
  end
end

defmodule ExIntegrationCoveralls.Cover do
  @moduledoc """
  Wrapper module for Erlang's cover tool.
  """

  @doc """
  Compile the beam files for coverage analysis.
  Accepts a single beam directory path or a list of beam directory paths.
  """
  def compile(compile_paths) when is_list(compile_paths) do
    :cover.stop()
    :cover.start()

    Enum.flat_map(compile_paths, fn path ->
      case :cover.compile_beam_directory(path |> string_to_charlist) do
        results when is_list(results) -> results
        error -> [error]
      end
    end)
  end

  def compile(compile_path) do
    :cover.stop()
    :cover.start()
    :cover.compile_beam_directory(compile_path |> string_to_charlist)
  end

  @doc """
  Release resource
  """
  def stop do
    :cover.stop()
  end

  @doc """
  Reset all coverage data
  """
  def reset() do
    :cover.reset()
  end

  @doc """
  Check the status of the cover server.
  """
  def check_cover_status do
    case :cover.start() do
      {:ok, _} -> :not_started
      {:error, {:already_started, _}} -> :already_started
    end
  end

  @doc """
  Returns the relative file path of the specified module for working directory.
  """
  def module_path(module) do
    get_module_source(module)
    |> Path.relative_to(ExIntegrationCoveralls.PathReader.base_path())
  end

  @doc """
  Returns the relative file path of the specified module for source_lib_absolute_path.
  """
  def module_path(module, source_lib_absolute_path) do
    get_module_source(module)
    |> Path.relative_to(source_lib_absolute_path)
  end

  @doc "Wrapper for :cover.modules"
  def modules do
    :cover.modules() |> Enum.filter(&has_compile_info?/1)
  end

  def modules(module_source_absolute_path) do
    :cover.modules()
    |> Enum.filter(fn module -> has_compile_info?(module, module_source_absolute_path) end)
  end

  def has_compile_info?(module, module_source_absolute_path \\ "") do
    source = get_module_source(module)

    cond do
      source != nil and File.exists?(source) -> true
      source != nil and File.exists?(module_source_absolute_path) -> true
      true ->
        log_missing_source(module)
        false
    end
  rescue
    _e ->
      log_missing_source(module)
      false
  end

  @doc """
  Returns modules whose compile-time source path starts with the given root.
  Used to partition modules by app when multiple apps are instrumented.
  """
  def modules_for_compile_root(compile_time_root) do
    :cover.modules()
    |> Enum.filter(&module_matches_root?(&1, compile_time_root))
  end

  defp module_matches_root?(module, compile_time_root) do
    case get_module_source(module) do
      nil -> false
      source -> String.starts_with?(source, compile_time_root)
    end
  end

  @doc "Wrapper for :cover.analyse https://www.erlang.org/doc/man/cover.html#analyse-3"
  def analyze(module) do
    :cover.analyse(module, :calls, :line)
  end

  # Returns the compile-time source file path for a module.
  # First tries module_info(:compile)[:source] (fast path, works in dev/test).
  # Falls back to reading the beam file's debug_info via :cover.is_compiled/1
  # (needed in release environments where beams are stripped of compile info).
  defp get_module_source(module) do
    case module.module_info(:compile) |> Keyword.get(:source) do
      path when not is_nil(path) ->
        List.to_string(path)

      nil ->
        source_from_cover_beam(module)
    end
  rescue
    _ -> source_from_cover_beam(module)
  end

  defp source_from_cover_beam(module) do
    case :cover.is_compiled(module) do
      {:file, beam_path} ->
        case :beam_lib.chunks(beam_path, [:debug_info]) do
          {:ok, {_, [{:debug_info, {:debug_info_v1, _, {_, info, _}}}]}} ->
            Map.get(info, :file)

          _ ->
            nil
        end

      _ ->
        nil
    end
  rescue
    _ -> nil
  end

  if Version.compare(System.version(), "1.3.0") == :lt do
    defp string_to_charlist(string), do: String.to_char_list(string)
  else
    defp string_to_charlist(string), do: String.to_charlist(string)
  end

  defp log_missing_source(module) do
    IO.puts(
      :stderr,
      "[warning] skipping the module '#{module}' because source information for the module is not available."
    )
  end
end

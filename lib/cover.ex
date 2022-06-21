defmodule ExIntegrationCoveralls.Cover do
  @moduledoc """
  Wrapper module for Erlang's cover tool.
  """

  @doc """
  Compile the beam files for coverage analysis.
  """
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
  Returns the relative file path of the specified module for working directory.
  """
  def module_path(module) do
    module.module_info(:compile)[:source]
    |> List.to_string()
    |> Path.relative_to(ExIntegrationCoveralls.PathReader.base_path())
  end

  @doc """
  Returns the relative file path of the specified module for source_lib_absolute_path.
  """
  def module_path(module, source_lib_absolute_path) do
    module.module_info(:compile)[:source]
    |> List.to_string()
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
    with info when not is_nil(info) <- module.module_info(:compile),
         path when not is_nil(path) <- Keyword.get(info, :source),
         true <- File.exists?(path) || File.exists?(module_source_absolute_path) do
      true
    else
      _e ->
        log_missing_source(module)
        false
    end
  rescue
    _e ->
      log_missing_source(module)
      false
  end

  @doc "Wrapper for :cover.analyse https://www.erlang.org/doc/man/cover.html#analyse-3"
  def analyze(module) do
    :cover.analyse(module, :calls, :line)
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

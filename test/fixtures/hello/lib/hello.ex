defmodule Hello do
  @moduledoc """
  Documentation for `Hello`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Hello.hello()
      :world

  """
  def hello do
    File.cwd!()
    :world
    File.cwd!()
    :hello
    File.cwd!()
    :world
  end
end

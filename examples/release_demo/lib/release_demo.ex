defmodule ReleaseDemo do
  @moduledoc """
  Main module with simple business logic functions that serve as coverage targets.
  """

  def hello do
    "Hello from ReleaseDemo!"
  end

  def add(a, b) do
    a + b
  end

  def greet(name) do
    "Hello, #{name}!"
  end
end

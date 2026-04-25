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

  @doc """
  Demonstrates cross-app call: uses DepLib.multiply/2 from the dep_lib dependency.
  """
  def square(n) do
    DepLib.multiply(n, n)
  end
end

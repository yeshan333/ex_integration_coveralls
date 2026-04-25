defmodule DepLib do
  @moduledoc """
  A small dependency library used to demonstrate multi-app coverage collection.
  """

  def multiply(a, b) do
    a * b
  end

  def reverse_string(str) do
    str |> String.graphemes() |> Enum.reverse() |> Enum.join()
  end

  def factorial(0), do: 1
  def factorial(n) when n > 0, do: n * factorial(n - 1)
end

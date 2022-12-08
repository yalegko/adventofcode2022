#!/usr/bin/env elixir

defmodule Matrix do
  def scenic_score(matrix, i, j) do
    size = Enum.count(matrix) - 1
    target_tree = matrix |> Enum.at(i) |> Enum.at(j)

    up = matrix |> column(j) |> Enum.take(i) |> Enum.reverse() |> count_visible(target_tree)
    down = matrix |> column(j) |> Enum.take(-(size - i)) |> count_visible(target_tree)
    left = matrix |> row(i) |> Enum.take(j) |> Enum.reverse() |> count_visible(target_tree)
    right = matrix |> row(i) |> Enum.take(-(size - j)) |> count_visible(target_tree)

    up * down * left * right
  end

  defp row(matrix, j), do: matrix |> Enum.at(j)
  defp column(matrix, i), do: matrix |> Enum.map(&Enum.at(&1, i))

  defp count_visible(seq, target) do
    num_visible =
      seq
      |> Enum.take_while(&(&1 < target))
      |> Enum.count()

    # If we stopped at the end of the forest -- take the counted value as is,
    # otherwise count the tree we were stumbled upon.
    #
    # TODO: Am I missing a way to do it in a single line?
    if num_visible == Enum.count(seq), do: num_visible, else: num_visible + 1
  end
end

[fname] = System.argv()

matrix =
  File.read!(fname)
  |> String.split()
  |> Enum.map(&String.codepoints/1)

size = Enum.count(matrix) - 1

for(i <- 0..size, j <- 0..size, do: {i, j})
|> Enum.map(fn {i, j} -> Matrix.scenic_score(matrix, i, j) end)
|> Enum.max()
|> IO.inspect()

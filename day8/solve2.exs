#!/usr/bin/env elixir

defmodule Matrix do
  def elem_at(matrix, i, j) do
    matrix
    |> Enum.at(i)
    |> Enum.at(j)
  end

  def scenic_score(matrix, i, j) do
    size = Enum.count(matrix) - 1

    up = cond do
      i == 0 -> 0
      i == 1 -> 1
      true -> visible_col(matrix, i, j, (i-1)..0)
    end
    down = cond do
      i == size -> 0
      i == size - 1 -> 1
      true -> visible_col(matrix, i, j, (i+1)..size)
    end
    left = cond do
      j == 0 -> 0
      j == 1 -> 1
      true -> visible_row(matrix, i, j, (j-1)..0)
    end
    right = cond do
      j == size -> 0
      j == size - 1 -> 1
      true -> visible_row(matrix, i, j, (j+1)..size)
    end

    up * down * left * right
  end

  defp visible_col(matrix, i, j, column_seq) do
    target_tree = elem_at(matrix, i, j)

    column_seq
    |> Enum.reduce(
      {0, :go},
      fn i, {sum, mark} ->
        eij = elem_at(matrix, i, j)
        cond do
          mark == :go and eij < target_tree -> {sum+1, :go}
          mark == :go -> {sum + 1, :stop}
          mark == :stop -> {sum, :stop}
        end
      end)
    |> elem(0)
  end

  defp visible_row(matrix, i, j, row_seq) do
    target_tree = elem_at(matrix, i, j)

    row_seq
    |> Enum.reduce(
      {0, :go},
      fn j, {sum, mark} ->
        eij = elem_at(matrix, i, j)
        cond do
          mark == :go and eij < target_tree -> {sum+1, :go}
          mark == :go -> {sum + 1, :stop}
          mark == :stop -> {sum, :stop}
        end
      end)
    |> elem(0)
  end
end

[fname] = System.argv()

matrix =
  File.read!(fname)
  |> String.split()
  |> Enum.map(&String.codepoints/1)

size = Enum.count(matrix) - 1

0..size
  |> Enum.flat_map(fn i ->
    Enum.map(0..size, fn j -> {i, j} end)
  end)
  |> Enum.reduce(0, fn {i, j}, max ->
    score = Matrix.scenic_score(matrix, i, j)
    cond do
      score > max -> score
      true -> max
    end
  end)
|> IO.inspect()

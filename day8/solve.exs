#!/usr/bin/env elixir

defmodule Matrix do
  # this crazy clever algorithm hails from
  # http://stackoverflow.com/questions/5389254/transposing-a-2-dimensional-matrix-in-erlang
  # and is apparently from the Haskell stdlib. I implicitly trust Haskellers.
  def transpose([[x | xs] | xss]) do
    [[x | (for [h | _] <- xss, do: h)] | transpose([xs | (for [_ | t] <- xss, do: t)])]
  end

  def transpose([[] | xss]), do: transpose(xss)

  def transpose([]), do: []

  def mark_visible(matrix) do
    matrix
    |> Enum.map(fn row ->
      row
      |> Enum.map(&({&1, :invisible}))
    end)
    |> mark_horizontal_visible()
    |> transpose()
    |> mark_horizontal_visible()
  end

  defp mark_horizontal_visible(marked_matrix) do
    marked_matrix
    |> mark_left_visible()
    |> Enum.map(&Enum.reverse/1)
    |> mark_left_visible()
    |> Enum.map(&Enum.reverse/1)
  end

  defp mark_left_visible(marked_matrix) do
    marked_matrix
    |> Enum.map(fn row ->
      row
      |> Enum.map_reduce("", fn
        {el, _mark}, max when el > max -> {{el, :visible}, el}
        {el, mark}, max -> {{el, mark}, max}
      end)
      |> elem(0)
    end)
  end
end

[fname] = System.argv()

File.read!(fname)
|> String.split()
|> Enum.map(&String.codepoints/1)

|> Matrix.mark_visible()

|> Enum.reduce(0, fn row, sum ->
  row_sum =
    row
    |> Enum.reduce(0, fn
      {_el, :visible}, sum -> sum + 1
      _, sum -> sum
    end)
  sum + row_sum
end)
|> IO.inspect()

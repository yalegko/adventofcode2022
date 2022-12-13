#!/usr/bin/env elixir

defmodule CMP do
  def less?(a, a) when is_integer(a), do: :equal
  def less?(a, b) when is_integer(a) and is_integer(b), do: a < b

  def less?([a | aa], [b | bb]) do
    case less?(a, b) do
      :equal -> less?(aa, bb)
      res -> res
    end
  end

  def less?([], [_b | _]), do: true
  def less?([_a | _], []), do: false
  def less?([], []), do: :equal

  def less?(a, b) when is_integer(a) and is_list(b), do: less?([a], b)
  def less?(a, b) when is_list(a) and is_integer(b), do: less?(a, [b])
end

[fname] = System.argv()

fname
|> File.stream!()

# Parse input.
|> Stream.map(&String.trim/1)
|> Stream.reject(&(&1 == ""))
|> Stream.map(&Code.eval_string/1)
|> Stream.map(&(&1 |> elem(0)))

# Mix new packets and sort everything.
|> Stream.concat([[[2]], [[6]]])
|> Enum.to_list()
|> Enum.sort(fn a, b -> CMP.less?(a, b) === true end)

# Find the indices of target packets.
|> Enum.with_index(1)
|> Enum.filter(fn {a, i} -> a == [[2]] or a == [[6]] end)

# Form the result.
|> Enum.map(&(&1 |> elem(1)))
|> Enum.reduce(&*/2)
|> IO.inspect(label: "Final result")

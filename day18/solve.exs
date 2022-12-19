#!/usr/bin/env elixir

defmodule Cube do
  def coords({x, y, z} = _cube) do
    [
      {x, y, z},
      {x + 1, y, z},
      {x, y + 1, z},
      {x, y, z + 1},
      {x + 1, y + 1, z},
      {x + 1, y, z + 1},
      {x, y + 1, z + 1},
      {x + 1, y + 1, z + 1}
    ]
  end

  def adjacent_side(c1, c2) do
    MapSet.intersection(
      c1 |> coords() |> MapSet.new(),
      c2 |> coords() |> MapSet.new()
    )
  end
end

[fname] = System.argv()

cubes =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, ","))
  |> Stream.map(fn coords ->
    coords
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end)
  |> Enum.to_list()

adjacent_sides =
  for c1 <- cubes, c2 <- cubes, c1 != c2, reduce: 0 do
    adj ->
      case Cube.adjacent_side(c1, c2) |> MapSet.size() do
        0 -> adj
        1 -> adj
        2 -> adj
        4 -> adj + 1
      end
  end
  |> IO.inspect(label: "adjacent")

(Enum.count(cubes) * 6 - adjacent_sides)
|> IO.inspect(label: "Num sides?")

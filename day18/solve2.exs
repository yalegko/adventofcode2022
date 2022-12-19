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

  def flood(space, _, {-2, _, _}), do: space
  def flood(space, _, {_, -2, _}), do: space
  def flood(space, _, {_, _, -2}), do: space
  def flood(space, _, {22, _, _}), do: space
  def flood(space, _, {_, 22, _}), do: space
  def flood(space, _, {_, _, 22}), do: space

  def flood(space, cubes, {x, y, z} = p) do
    if MapSet.member?(cubes, p) do
      space
    else
      [
        {x + 1, y, z},
        {x, y + 1, z},
        {x, y, z + 1},
        {x - 1, y, z},
        {x, y - 1, z},
        {x, y, z - 1}
      ]
      |> Enum.reject(fn coord -> space |> MapSet.member?(coord) end)
      |> Enum.reduce(MapSet.put(space, p), fn coord, space -> flood(space, cubes, coord) end)
    end
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
  |> MapSet.new()

outer_space =
  MapSet.new()
  |> Cube.flood(cubes, {0, 0, 0})

outer_space
|> MapSet.size()
|> IO.inspect(label: "szie of space")

for c1 <- cubes, c2 <- outer_space, reduce: 0 do
  adj ->
    case Cube.adjacent_side(c1, c2) |> MapSet.size() do
      0 -> adj
      1 -> adj
      2 -> adj
      4 -> adj + 1
    end
end
|> IO.inspect(label: "adjacent")

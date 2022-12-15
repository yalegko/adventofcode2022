#!/usr/bin/env elixir

defmodule Field do
  def dist({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  def is_scannable([scanner, beam], point) do
    dist(scanner, point) <= dist(scanner, beam)
  end
end

[fname] = System.argv()

coords =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(fn line ->
    ~r/x=([\-\d]+), y=([\-\d]+)/
    |> Regex.scan(line, capture: :all_but_first)
    |> Enum.map(fn pair -> pair |> Enum.map(&String.to_integer/1) end)
    |> Enum.map(&List.to_tuple/1)
  end)
  |> Enum.to_list()

the_y = if fname == "input.txt", do: 2_000_000, else: 10

{x1, x2} =
  coords
  |> Enum.filter(fn [{_sx, sy} = scanner, beam] ->
    abs(sy - the_y) <= Field.dist(scanner, beam)
  end)
  |> Enum.map(fn [{sx, sy} = scanner, {bx, by} = beam] ->
    dx = Field.dist(scanner, beam) - abs(sy - the_y)

    {sx - dx, sx + dx}
  end)
  |> Enum.sort()
  |> IO.inspect(label: "Sorted")
  |> Enum.reduce([], fn
    p, [] -> [p]
    {x1, x2}, [{acc1, acc2} | rest] when x1 <= acc2 -> [{acc1, max(x2, acc2)} | rest]
    {x1, x2}, acc -> [{x1, x2} | acc]
  end)
  |> IO.inspect(label: "Intersected")
  |> Enum.at(0)

occupied =
  coords
  |> Enum.flat_map(& &1)
  |> Enum.filter(fn {x, y} -> x1 <= x and x <= x2 and y == the_y end)
  |> Enum.uniq()
  |> IO.inspect(label: "Occupied")
  |> Enum.count()

(x2 - x1 - occupied + 1)
|> IO.inspect(label: "Res")

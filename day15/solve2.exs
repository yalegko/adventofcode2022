#!/usr/bin/env elixir

defmodule Field do
  def dist({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  def find_x_coverage(coords, the_y) do
    coords
    |> Enum.filter(fn [{_sx, sy} = scanner, beam] ->
      abs(sy - the_y) <= Field.dist(scanner, beam)
    end)
    |> Enum.map(fn [{sx, sy} = scanner, beam] ->
      dx = Field.dist(scanner, beam) - abs(sy - the_y)

      {sx - dx, sx + dx}
    end)
    |> Enum.sort()
    |> Enum.reduce([], fn
      p, [] -> [p]
      {x1, x2}, [{acc1, acc2} | rest] when x1 - 1 <= acc2 -> [{acc1, max(x2, acc2)} | rest]
      {x1, x2}, acc -> [{x1, x2} | acc]
    end)
    |> Enum.reverse()
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

max_y = if fname == "input.txt", do: 4_000_000, else: 20

[{y, [{_, x1}, {x2, _}]}] =
  ans =
  0..max_y
  |> Enum.map(fn y -> {y, Field.find_x_coverage(coords, y)} end)
  |> Enum.filter(fn {_y, xxs} -> Enum.count(xxs) > 1 end)
  |> IO.inspect(label: "Intervals")

if x2 != x1 + 2,
  do: IO.inspect(ans, label: "Unexpected answer")

((x1 + 1) * max_y + y)
|> IO.inspect(label: "Result")

#!/usr/bin/env elixir

defmodule Field do
  def new(), do: %{}

  def add_row(field, row, y) do
    row
    |> Enum.with_index(1)
    |> Enum.reduce(field, fn {c, x}, field -> Map.put(field, {x, y}, c) end)
  end

  def turn_cw(">"), do: "v"
  def turn_cw("v"), do: "<"
  def turn_cw("<"), do: "^"
  def turn_cw("^"), do: ">"
  def turn_ccw(dirc), do: 1..3 |> Enum.reduce(dirc, fn _, dir -> turn_cw(dir) end)

  def move({field, {xc, yc, dirc}}, "R"), do: {field, {xc, yc, turn_cw(dirc)}}
  def move({field, {xc, yc, dirc}}, "L"), do: {field, {xc, yc, turn_ccw(dirc)}}

  def move({field, {xc, yc, dirc} = cursor}, steps) when is_integer(steps) do
    new_cursor =
      for _ <- 1..steps, reduce: cursor do
        cursor ->
          field |> do_step(cursor)
      end

    {field, new_cursor}
  end

  defp move_cursor({xc, yc, dir}) do
    case dir do
      ">" -> {xc + 1, yc, dir}
      "v" -> {xc, yc + 1, dir}
      "<" -> {xc - 1, yc, dir}
      "^" -> {xc, yc - 1, dir}
    end
  end

  def at(field, {xc, yc, _dir} = _cursor, default \\ nil),
    do: Map.get(field, {xc, yc}, default)

  def do_step(field, cursor) do
    new_cursor = cursor |> move_cursor()

    case field |> at(new_cursor, " ") do
      "#" ->
        cursor

      "." ->
        new_cursor

      " " ->
        overlapped_cursor = field |> overlap(cursor)

        case field |> at(overlapped_cursor) do
          "#" -> cursor
          "." -> overlapped_cursor
        end
    end
  end

  def side(), do: 50

  def overlap(field, {xc, yc, ">"}) do
    side = side_num(xc, yc)
    {sx, sy} = to_side_coords(xc, yc)

    case side do
      1 -> {sx, side() + 1 - sy, "<", 4}
      2 -> {side(), sy, ">", 1}
      3 -> {sy, side(), "^", 1}
      4 -> {sx, side() + 1 - sy, "<", 1}
      5 -> {side(), sy, ">", 4}
      6 -> {sy, side(), "^", 4}
    end
    |> from_side_coord()
  end

  def overlap(field, {xc, yc, "v"}) do
    side = side_num(xc, yc)
    {sx, sy} = to_side_coords(xc, yc)

    case side do
      1 -> {side(), sx, "<", 3}
      2 -> {sx, 1, "v", 3}
      3 -> {sx, 1, "v", 4}
      4 -> {side(), sx, "<", 6}
      5 -> {sx, 1, "v", 6}
      6 -> {sx, 1, "v", 1}
    end
    |> from_side_coord()
  end

  def overlap(field, {xc, yc, "<"}) do
    side = side_num(xc, yc)
    {sx, sy} = to_side_coords(xc, yc)

    case side do
      1 -> {side(), sy, "<", 2}
      2 -> {1, side() + 1 - sy, ">", 5}
      3 -> {sy, 1, "v", 5}
      4 -> {side(), sy, "<", 5}
      5 -> {1, side() + 1 - sy, ">", 2}
      6 -> {sy, 1, "v", 2}
    end
    |> from_side_coord()
  end

  def overlap(field, {xc, yc, "^"}) do
    side = side_num(xc, yc)
    {sx, sy} = to_side_coords(xc, yc)

    case side do
      1 -> {sx, side(), "^", 6}
      2 -> {1, sx, ">", 6}
      3 -> {sx, side(), "^", 2}
      4 -> {sx, side(), "^", 3}
      5 -> {1, sx, ">", 3}
      6 -> {sx, side(), "^", 5}
    end
    |> from_side_coord()
  end

  def side_num(x, y) do
    cond do
      2 * side() + 1 <= x and x <= 3 * side() and 1 <= y and y <= side() -> 1
      side() + 1 <= x and x <= 2 * side() and 1 <= y and y <= side() -> 2
      side() + 1 <= x and x <= 2 * side() and side() + 1 <= y and y <= 2 * side() -> 3
      side() + 1 <= x and x <= 2 * side() and 2 * side() + 1 <= y and y <= 3 * side() -> 4
      1 <= x and x <= side() and 2 * side() + 1 <= y and y <= 3 * side() -> 5
      1 <= x and x <= side() and 3 * side() + 1 <= y and y <= 4 * side() -> 6
      true -> throw("#{inspect({x, y})}")
    end
  end

  def to_side_coords(xc, yc) do
    case side_num(xc, yc) do
      1 -> {xc - 2 * side(), yc}
      2 -> {xc - side(), yc}
      3 -> {xc - side(), yc - side()}
      4 -> {xc - side(), yc - 2 * side()}
      5 -> {xc, yc - 2 * side()}
      6 -> {xc, yc - 3 * side()}
    end
  end

  def from_side_coord({xc, yc, dir, side}) do
    case side do
      1 -> {xc + 2 * side(), yc, dir}
      2 -> {xc + side(), yc, dir}
      3 -> {xc + side(), yc + side(), dir}
      4 -> {xc + side(), yc + 2 * side(), dir}
      5 -> {xc, yc + 2 * side(), dir}
      6 -> {xc, yc + 3 * side(), dir}
    end
  end

  def visualize({field, {xc, yc, dir} = cursor}) do
    {maxx, maxy} = field |> maxes()
    mapped = Map.put(field, {xc, yc}, dir)

    IO.inspect(cursor, label: "Cursor")

    for y <- 1..maxy do
      (["|"] ++ for(x <- 1..maxx, do: Map.get(mapped, {x, y}, " ")) ++ ["|"])
      |> Enum.join()
      |> IO.puts()
    end

    IO.puts("")

    {field, cursor}
  end

  def maxes(field) do
    field
    |> Enum.reduce({-1, -1}, fn {{x, y}, _c}, {maxx, maxy} -> {max(maxx, x), max(maxy, y)} end)
  end
end

[fname] = System.argv()

field =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim(&1, "\n"))
  |> Stream.map(&String.graphemes/1)
  |> Stream.take_while(&(length(&1) > 0))
  |> Stream.with_index(1)
  |> Stream.scan(Field.new(), fn {row, y}, field -> field |> Field.add_row(row, y) end)
  |> Stream.take(-1)
  |> Enum.at(0)

sx =
  field
  |> Enum.filter(fn {{x, y}, c} -> y == 1 and c == "." end)
  |> Enum.map(fn {{x, y}, c} -> x end)
  |> Enum.min()
  |> IO.inspect(label: "start pos")

start_cursor = {sx, 1, ">"}

# {field, start_cursor}
# |> Field.visualize()

{_, maxy} = field |> Field.maxes()

path =
  fname
  |> File.stream!()
  |> Stream.drop(maxy + 1)
  |> Enum.at(0)
  |> IO.inspect()
  |> String.graphemes()
  |> Enum.reduce({[], ""}, fn
    "R", {path, cur} -> {path ++ [String.to_integer(cur), "R"], ""}
    "L", {path, cur} -> {path ++ [String.to_integer(cur), "L"], ""}
    dig, {path, cur} -> {path, cur <> dig}
  end)
  |> then(fn {path, last} -> path ++ [String.to_integer(last)] end)
  |> IO.inspect()

{xc, yc, dirc} =
  path
  |> Enum.reduce({field, start_cursor}, fn dir, field_n_cursor ->
    field_n_cursor
    |> Field.move(dir)

    # |> Field.visualize()
  end)
  |> elem(1)
  |> IO.inspect()

[">", "v", "<", "^"]
|> Enum.find_index(&(&1 == dirc))
|> then(&(&1 + 1000 * yc))
|> then(&(&1 + 4 * xc))
|> IO.inspect(label: "Code")

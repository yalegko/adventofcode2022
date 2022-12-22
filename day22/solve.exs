#!/usr/bin/env elixir

defmodule Field do
  def new(), do: %{}

  def add_row(field, row, y) do
    row
    |> Enum.with_index(1)
    |> Enum.reduce(field, fn {c, x}, field -> Map.put(field, {x, y}, c) end)
  end

  def move({field, {xc, yc, dirc}}, "R"), do: {field, {xc, yc, turn_cw(dirc)}}
  def move({field, {xc, yc, dirc}}, "L"), do: {field, {xc, yc, turn_ccw(dirc)}}

  def move({field, {xc, yc, dirc} = cursor}, steps) when is_integer(steps) do
    new_cursor =
      for _ <- 1..steps, reduce: cursor do
        cursor -> field |> do_step(cursor)
      end

    {field, new_cursor}
  end

  def do_step(field, {xc, yc, dir} = cursor) do
    {newx, newy} =
      case dir do
        ">" -> {xc + 1, yc}
        "v" -> {xc, yc + 1}
        "<" -> {xc - 1, yc}
        "^" -> {xc, yc - 1}
      end

    case Map.get(field, {newx, newy}, " ") do
      "#" ->
        {xc, yc, dir}

      "." ->
        {newx, newy, dir}

      " " ->
        {ox, oy} = field |> overlap(cursor)

        case Map.fetch!(field, {ox, oy}) do
          "." -> {ox, oy, dir}
          "#" -> {xc, yc, dir}
        end
    end
  end

  def overlap(field, {xc, yc, ">"}) do
    x =
      field
      |> Enum.filter(fn {{x, y}, c} -> y == yc and c != " " end)
      |> Enum.map(fn {{x, _y}, _c} -> x end)
      |> Enum.min()

    {x, yc}
  end

  def overlap(field, {xc, yc, "<"}) do
    x =
      field
      |> Enum.filter(fn {{x, y}, c} -> y == yc and c != " " end)
      |> Enum.map(fn {{x, _y}, _c} -> x end)
      |> Enum.max()

    {x, yc}
  end

  def overlap(field, {xc, yc, "^"}) do
    y =
      field
      |> Enum.filter(fn {{x, y}, c} -> x == xc and c != " " end)
      |> Enum.map(fn {{_x, y}, _c} -> y end)
      |> Enum.max()

    {xc, y}
  end

  def overlap(field, {xc, yc, "v"}) do
    y =
      field
      |> Enum.filter(fn {{x, y}, c} -> x == xc and c != " " end)
      |> Enum.map(fn {{_x, y}, _c} -> y end)
      |> Enum.min()

    {xc, y}
  end

  def turn_cw(">"), do: "v"
  def turn_cw("v"), do: "<"
  def turn_cw("<"), do: "^"
  def turn_cw("^"), do: ">"

  def turn_ccw(dirc), do: 1..3 |> Enum.reduce(dirc, fn _, dir -> turn_cw(dir) end)

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

{field, start_cursor}
|> Field.visualize()

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

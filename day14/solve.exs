#!/usr/bin/env elixir

defmodule Field do
  defstruct map: nil, min: {100_500, 100_500}, max: {-100_500, -100_500}

  def new(lines_stream) do
    field =
      lines_stream
      |> Stream.scan(Map.new(), fn [from, to], map -> map |> draw_line(from, to) end)
      |> Stream.take(-1)
      |> Enum.at(0)

    {minx, miny, maxx, maxy} =
      field
      |> Enum.reduce(
        {100_500, 100_500, -100_500, -100_500},
        fn {{x, y}, _char}, {minx, miny, maxx, maxy} ->
          {min(x, minx), min(y, miny), max(x, maxx), max(y, maxy)}
        end
      )

    %Field{map: field, min: {minx, miny}, max: {maxx, maxy}}
  end

  def sandfall(field, source) do
    case drop(field, source) do
      {field, :ok} -> sandfall(field, source)
      {field, :end} -> field
    end
  end

  def drop(%Field{max: {_maxx, maxy}} = field, {_x, y}) when y > maxy,
    do: {field, :end}

  def drop(field, {x, y}) do
    # field |> visualize()

    target =
      [{x, y + 1}, {x - 1, y + 1}, {x + 1, y + 1}]
      |> Enum.find(nil, fn p -> field |> at(p) == "." end)

    case target do
      nil ->
        {
          %Field{field | map: Map.put(field.map, {x, y}, "o")},
          :ok
        }

      point ->
        drop(field, point)
    end
  end

  def visualize(field) do
    %Field{min: {minx, miny}, max: {maxx, maxy}} = field

    # IO.ANSI.clear()

    (miny - 3)..(maxy + 3)
    |> Enum.each(fn y ->
      (minx - 3)..(maxx + 3)
      |> Enum.map(fn x -> at(field, {x, y}) end)
      |> Enum.join()
      |> IO.puts()
    end)

    # :timer.sleep(10)

    field
  end

  defp draw(map, point, char),
    do: map |> Map.put(point, char)

  defp draw_line(map, {x1, y1}, {x2, y2}) when x1 == x2,
    do: y1..y2 |> Enum.reduce(map, fn y, map -> map |> draw({x1, y}, "#") end)

  defp draw_line(map, {x1, y1}, {x2, y2}) when y1 == y2,
    do: x1..x2 |> Enum.reduce(map, fn x, map -> map |> draw({x, y1}, "#") end)

  defp at(%Field{map: map}, p) when is_map_key(map, p), do: Map.fetch!(map, p)
  defp at(_field, _p), do: "."
end

[fname] = System.argv()

field =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, " -> "))
  |> Stream.flat_map(&Enum.chunk_every(&1, 2, 1))
  |> Stream.filter(fn chunk -> Enum.count(chunk) == 2 end)
  |> Stream.map(fn line ->
    line
    |> Enum.map(fn coord ->
      coord
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end)
  end)
  |> Field.new()
  |> Field.visualize()
  |> Field.sandfall({500, 0})
  |> Field.visualize()

field.map
|> Enum.count(fn {_point, char} -> char == "o" end)
|> IO.inspect()

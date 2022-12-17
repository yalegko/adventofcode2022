#!/usr/bin/env elixir

defmodule Shape do
  defstruct coords: [], num: 0

  def next(num, y) do
    next_num = rem(num + 1, 5)
    coords = case next_num do
      0 -> [{2, y}, {3, y}, {4, y}, {5, y}]
      1 -> [{3, y}, {2, y+1}, {3, y+1}, {4, y+1}, {3, y+2}]
      2 -> [{2, y}, {3, y}, {4, y}, {4, y+1}, {4, y+2}]
      3 -> [{2, y}, {2, y+1}, {2, y+2}, {2, y+3}]
      4 -> [{2, y}, {3, y}, {2, y+1}, {3, y+1}]
    end

    %Shape{num: next_num, coords: coords}
  end

  def move(shape, ">") do
    cond do
      right_most(shape) == 6 -> shape
      true -> %Shape{shape | coords: shape.coords |> Enum.map(fn {x, y} -> {x + 1, y} end)}
    end
  end

  def move(shape, "<") do
    cond do
      left_most(shape) == 0 -> shape
      true -> %Shape{shape | coords: shape.coords |> Enum.map(fn {x, y} -> {x - 1, y} end)}
    end
  end

  def move(shape, :down) do
    %Shape{shape | coords: shape.coords |> Enum.map(fn {x, y} -> {x, y - 1} end)}
  end

  def left_most(shape),
    do: shape.coords |> Enum.map(fn {x, _y} -> x end) |> Enum.min()
  def right_most(shape),
    do: shape.coords |> Enum.map(fn {x, _y} -> x end) |> Enum.max()
  def down_most(shape),
    do: shape.coords |> Enum.map(fn {_x, y} -> y end) |> Enum.min()
end


defmodule Field do
  def new() do
    for i <- 0..6, reduce: Map.new() do
      map -> Map.put(map, {i, 0}, "-")
    end
  end

  def do_step(field, shape, dir, num_merged) do
      moved = shape |> Shape.move(dir)
      moved = cond do
        field |> collides(moved) -> shape
        true -> moved
      end

      dropped = moved |> Shape.move(:down)

      if not collides(field, dropped) do
        {field, dropped, num_merged}
      else
        field = field |> merge(moved)
        max_y = field |> find_max_y()

        {field, Shape.next(shape.num, max_y + 4), num_merged + 1}
      end
  end

  def merge(field, shape) do
    new_field =
      shape.coords
      |> Enum.reduce(field, fn p, field -> Map.put(field, p, "#") end)

    max_y = new_field |> find_max_y()
    min_y = new_field |> find_min_y()

    cut_from =
      for y <- max_y..min_y, x <- 0..6,
          Map.has_key?(new_field, {x, y}),
          reduce: Map.new() do
        acc ->
            Map.put_new(acc, x, y)
      end
      # |> IO.inspect(label: "Cut array")
      |> Enum.map(fn {_x, y} -> y end)
      |> Enum.min()
      # |> IO.inspect(label: "Cut from")

    new_field
      |> Enum.reject(fn {{_x, y}, _char} -> y < cut_from end)
      |> Map.new()
  end

  def collides(field, shape) do
    shapemap = shape.coords |> MapSet.new()

    field
    |> Enum.any?(fn {coord, _char} -> MapSet.member?(shapemap, coord) end)
  end

  def visualize(field, shape) do
    field_with_shape =
      shape.coords
      |> Enum.reduce(field, fn c, field -> Map.put(field, c, "@") end)

    for y <- find_max_y(field_with_shape)+3..find_min_y(field_with_shape) do
      ["|"]
      |> Enum.concat(
        for x <- 0..6, do: Map.get(field_with_shape, {x, y}, ".")
      )
      |> Enum.concat(["|"])
      |> Enum.join()
      |> IO.puts()
    end

    field
  end

  def find_max_y(field),
    do: field |> Enum.map(fn {{_x, y}, _char} -> y end)|> Enum.max()
  def find_min_y(field),
    do: field |> Enum.map(fn {{_x, y}, _char} -> y end)|> Enum.min()

  def hash(field) do
    min_y = field |> find_min_y()

    field
    |> Enum.map(fn {{x, y}, _char} -> {x, y-min_y} end)
    |> Enum.sort()
  end
end

[fname] = System.argv()

pattern =
  fname
  |> File.read!()
  |> String.graphemes()

pattern
|> Enum.with_index()
|> Stream.cycle()
|> Stream.transform(
  {Field.new(), Shape.next(-1, 4), 0, Map.new()},
  fn
    _move, {field, _shape, dropped, _seen} when dropped == 1000000000000 -> {:halt, :halt}

    {move, i}, {field, shape, dropped, seen} ->
      seen_pattern = {i, shape.num, Field.hash(field)}
      if Map.has_key?(seen, seen_pattern) do
        IO.puts("Found collision at #{dropped}, previous at #{inspect(seen[seen_pattern])}")
        {:halt, :halt}
      else
        {new_field, shape, dropped} =
          field
          |> Field.do_step(shape, move, dropped)

        {[{dropped, new_field}], {new_field, shape, dropped, Map.put(seen, seen_pattern, {dropped, field})}}
      end
  end
)
|> Stream.take(-1)
|> Enum.at(0)
|> IO.inspect()

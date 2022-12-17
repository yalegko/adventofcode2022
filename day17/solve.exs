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
    shape.coords
    |> Enum.reduce(field, fn p, field -> Map.put(field, p, "#") end)
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

    for y <- find_max_y(field_with_shape)+3..0 do
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

  def find_max_y(field) do
    field
    |> Enum.reject(fn {_coord, char} -> char == "." end)
    |> Enum.map(fn {{_x, y}, _char} -> y end)
    |> Enum.max()
  end
end

[fname] = System.argv()

pattern =
  fname
  |> File.read!()
  |> String.graphemes()

pattern
|> Stream.cycle()
|> Stream.transform(
  {Field.new(), Shape.next(-1, 4), 0},
  fn
    _move, {field, _shape, dropped} when dropped == 2022 -> {:halt, field}

    move, {field, shape, dropped} ->
      # IO.inspect("Dropped: #{dropped} // Moving #{move}")

      acc =
        field
        # |> Field.visualize(shape)
        |> Field.do_step(shape, move, dropped)

      {[elem(acc, 0)], acc}
  end
)
|> Stream.take(-1)
|> Enum.at(0)
|> Field.find_max_y()
|> IO.inspect()

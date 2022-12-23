#!/usr/bin/env elixir

defmodule Field do
  def do_step(field, round) do
    propose(field, round)
    |> Enum.reduce(field, fn
      {pos, [a, b | rest]}, field -> field
      {new_pos, [old_pos]}, field -> field |> MapSet.delete(old_pos) |> MapSet.put(new_pos)
    end)
  end

  def propose(field, round) do
    pattern =
      pattern(round)
      |> IO.inspect(label: "Pattern")

    field
    |> Enum.reduce(%{}, fn elf, acc ->
      case field |> propose_elf(elf, pattern) do
        nil -> acc
        pos -> Map.update(acc, pos, [elf], fn old -> [elf | old] end)
      end
    end)
  end

  def propose_elf(field, {x, y}, pattern) do
    adjacent =
      [
        {x + 1, y},
        {x, y + 1},
        {x + 1, y + 1},
        {x + 1, y - 1},
        {x - 1, y},
        {x, y - 1},
        {x - 1, y - 1},
        {x - 1, y + 1}
      ]
      |> Enum.reject(fn point -> MapSet.member?(field, point) end)

    proposed =
      if length(adjacent) == 8 do
        nil
      else
        pattern
        # |> IO.inspect(label: "? #{inspect({x, y})}")
        |> Enum.map(fn
          :N -> [{x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1}]
          :S -> [{x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}]
          :W -> [{x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1}]
          :E -> [{x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1}]
        end)
        # |> IO.inspect(label: "pattern")
        |> Enum.find(&(&1 |> Enum.all?(fn point -> not MapSet.member?(field, point) end)))

        # |> IO.inspect(label: "Propose {#{x},#{y}}")
      end

    if proposed == nil, do: nil, else: proposed |> Enum.at(1)
  end

  def pattern(round) do
    case rem(round, 4) do
      0 -> [:N, :S, :W, :E]
      1 -> [:S, :W, :E, :N]
      2 -> [:W, :E, :N, :S]
      3 -> [:E, :N, :S, :W]
    end
  end

  def visualize(field) do
    {{minx, miny}, {maxx, maxy}} = field |> corners()

    IO.inspect({{minx, miny}, {maxx, maxy}}, label: "Frontier")

    for y <- (miny - 1)..(maxy + 1) do
      for(x <- (minx - 1)..(maxx + 1), do: if(MapSet.member?(field, {x, y}), do: "#", else: "."))
      |> Enum.join()
      |> IO.puts()
    end

    IO.puts("")

    field
  end

  def corners(field) do
    field
    |> Enum.reduce(
      {{100_500, 100_500}, {-1, -1}},
      fn {x, y}, {{minx, miny}, {maxx, maxy}} ->
        {
          {min(minx, x), min(miny, y)},
          {max(maxx, x), max(maxy, y)}
        }
      end
    )
  end
end

[fname] = System.argv()

field =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.graphemes/1)
  |> Stream.map(&Enum.with_index/1)
  |> Stream.with_index(0)
  |> Stream.flat_map(fn {line, y} ->
    line
    |> Enum.filter(fn {c, _x} -> c == "#" end)
    |> Enum.map(fn {_c, x} -> {x, y} end)
  end)
  |> Stream.scan(MapSet.new(), fn {x, y}, acc -> MapSet.put(acc, {x, y}) end)
  |> Stream.take(-1)
  |> Enum.at(0)
  |> Field.visualize()

moved =
  for i <- 0..9, reduce: field do
    field ->
      # IO.puts("Round #{i}")
      field
      |> Field.do_step(i)

      # |> Field.visualize()
  end

{{minx, miny}, {maxx, maxy}} =
  moved
  |> Field.corners()
  |> IO.inspect(label: "Corners:")

MapSet.size(field)
|> IO.inspect()

((maxx - minx + 1) * (maxy - miny + 1) - MapSet.size(moved))
|> IO.inspect(label: "Free space")

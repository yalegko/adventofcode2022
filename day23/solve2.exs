#!/usr/bin/env elixir

defmodule Field do
  def do_step(field, round) do
    propose(field, round)
    |> Enum.reduce(field, fn
      # Two or more elves took the single spot -- don't move any of them.
      {_pos, [_a, _b | _rest]}, field -> field
      # Just one elf chose wisely.
      {new_pos, [old_pos]}, field -> field |> MapSet.delete(old_pos) |> MapSet.put(new_pos)
    end)
  end

  # Returns a map of new positions to the list of elves who proposed it.
  defp propose(field, round) do
    pattern = pattern(round)

    field
    |> Enum.reduce(%{}, fn elf, acc ->
      case field |> propose_elf(elf, pattern) do
        nil -> acc
        pos -> Map.update(acc, pos, [elf], fn old -> [elf | old] end)
      end
    end)
  end

  # Returns `nil` or the movement ({new_x, new_y}) proposed by the elf.
  defp propose_elf(field, elf, pattern) do
    taken_adjacent =
      pattern
      |> Enum.flat_map(&adjacent_to(elf, &1))
      |> MapSet.new()
      |> MapSet.intersection(field)
      |> MapSet.size()

    proposed =
      if taken_adjacent == 0 do
        nil
      else
        pattern
        |> Enum.map(&adjacent_to(elf, &1))
        |> Enum.find(&(&1 |> Enum.all?(fn point -> not MapSet.member?(field, point) end)))
      end

    # All moves are ordered as [diagonal, move, diagonal], so we need a middle one.
    if proposed == nil, do: nil, else: proposed |> Enum.at(1)
  end

  defp adjacent_to({x, y}, :N), do: [{x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1}]
  defp adjacent_to({x, y}, :S), do: [{x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}]
  defp adjacent_to({x, y}, :W), do: [{x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1}]
  defp adjacent_to({x, y}, :E), do: [{x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1}]

  defp pattern(0), do: [:N, :S, :W, :E]
  defp pattern(round) when round > 3, do: pattern(rem(round, 4))

  defp pattern(round),
    do: 0..(round - 1) |> Enum.reduce(pattern(0), fn _, [m | rest] -> rest ++ [m] end)

  def visualize(field) do
    {{minx, miny}, {maxx, maxy}} = field |> corners()

    IO.inspect({{minx, miny}, {maxx, maxy}}, label: "Size of Field")

    for y <- (miny - 1)..(maxy + 1) do
      for(x <- (minx - 1)..(maxx + 1), do: if(MapSet.member?(field, {x, y}), do: "#", else: "."))
      |> Enum.join()
      |> IO.puts()
    end

    IO.puts("")

    field
  end

  # Returns {left,top} {right, bottom} corners of the Field.
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

# |> Field.visualize()

0..9999
|> Stream.transform(field, fn i, field ->
  stepped = field |> Field.do_step(i)

  if MapSet.equal?(stepped, field),
    do: {:halt, field},
    else: {[i + 2], stepped}
end)
|> Stream.take(-1)
|> Enum.at(0)
|> IO.inspect(label: "Final step")

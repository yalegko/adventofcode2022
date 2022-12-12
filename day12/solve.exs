#!/usr/bin/env elixir

defmodule Matrix do
  def traverse(matrix, start) do
    visit(matrix, start, 0, MapSet.new(), [])
  end

  def bfs(matrix, queue, visited \\ MapSet.new()) do
    if :queue.is_empty(queue) do
      {queue, visited}
    else
      {{:value, el}, queue} = :queue.out(queue)
      {{i,j}=point, depth} = el
      # IO.puts("Visiting (#{i},#{j})")

      if matrix |> at(point) == ?E do
        IO.puts("Found new way of length #{depth}")
        {queue, visited}
      else

        nn =
          [{i+1, j}, {i-1, j}, {i, j+1}, {i, j-1}]
          |> Enum.filter(fn to -> not_visited(visited, to) and can_go?(matrix, point, to) end)

        visited =
          nn
          |> Enum.reduce(visited, fn to, visited -> MapSet.put(visited, to) end)
        queue =
          nn
          |> Enum.reduce(queue, fn to, queue ->  :queue.in({to, depth+1}, queue) end)

        # visualize(matrix, visited, queue, point)

        bfs(matrix, queue, visited)
      end
    end
  end

  def find_path_len(path, matrix) do
    path
    |> Enum.find(fn {point, _depth} -> matrix |> at(point) == ?E end)
    |> elem(1)
  end

  def visit(matrix, {i, j} = point, depth, visited, lengths) do
    if matrix |> at(point) == ?E do
      IO.puts("Found new way of length #{depth}")
      {visited, [depth | lengths]}
    else
      visited = MapSet.put(visited, point)
      # visualize(matrix, visited, point)

      {visited, lengths} =
        {matrix, {visited, lengths}}
        |> mb_visit(point, {i+1, j}, depth + 1)
        |> mb_visit(point, {i-1, j}, depth + 1)
        |> mb_visit(point, {i, j+1}, depth + 1)
        |> mb_visit(point, {i, j-1}, depth + 1)
        |> elem(1)

      {MapSet.delete(visited, point), lengths}
    end
  end

  defp mb_visit({matrix, {visited, lengths}}, from, to, depth) do
    cond do
      not_visited(visited, to) and can_go?(matrix, from, to)  ->
        {matrix, visit(matrix, to, depth, visited, lengths)}
      true ->
        {matrix, {visited, lengths}}
    end
  end

  def not_visited(visited, to), do: not MapSet.member?(visited, to)

  def can_go?(matrix, from, {x, y} = to) do
    to_height = case matrix |> at(to) do
      ?E -> ?z
      v -> v
    end
    from_height = case matrix |> at(from) do
      ?S -> ?a
      v -> v
    end
    x >= 0 and y >= 0 and to_height != nil and (to_height - from_height <= 1)
  end

  def at(matrix, {i, j}) do
    case matrix |> Enum.at(i) do
      nil -> nil
      row ->  row |> Enum.at(j)
    end
  end

  defp str_tuple({x, y}), do: "(#{x}, #{y})"

  defp visualize(matrix, visited, queue, {i, j} = to) do
    field = 0..40 |> Enum.reduce([], fn _, acc ->
      acc ++ [(for _ <- 0..178, do: ".")]
    end)

    # field =
    #   matrix
    #   |> Enum.map(fn row ->
    #     row
    #     |> Enum.map(&(List.to_string([&1])))
    #   end)

    IO.write(IO.ANSI.clear)
    IO.puts("Go to #{to |> str_tuple}. Already visited #{visited |> MapSet.size}. Queued #{:queue.len(queue)}")


    visited
    |> Enum.reduce(field, fn {i,j}, field ->
      new_row =
        field
        |> Enum.at(i)
        |> List.replace_at(j, "#")
      List.replace_at(field, i, new_row)
    end)
    |> List.update_at(i, fn row -> row |> List.replace_at(j, IO.ANSI.green <> "X" <> IO.ANSI.reset) end)
    |> Enum.map(&Enum.join/1)
    |> Enum.each(&IO.puts/1)

    :timer.sleep(10)

  end
end

[fname] = System.argv()

matrix =
  File.read!(fname)
  |> String.split()
  |> Enum.map(&String.to_charlist/1)

start =
  matrix
  |> Enum.find_index(fn row -> Enum.find(row, &(&1 == ?S)) != nil end)
  |> (fn row_idx -> {row_idx, matrix |> Enum.at(row_idx) |> Enum.find_index(&(&1 == ?S))} end).()
  |> IO.inspect()

# matrix
# |> Matrix.traverse(start)
# |> elem(1)
# |> Enum.min()
# |> IO.inspect()

matrix
|> Matrix.bfs(:queue.in({start, 0}, :queue.new()))
# |> IO.inspect()
# |> elem(1)
# |> :queue.to_list()
# |> Enum.map(fn {point, depth} -> {Matrix.at(matrix, point), depth} end)
# |> Matrix.find_path_len(matrix)

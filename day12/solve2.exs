#!/usr/bin/env elixir

defmodule Matrix do
  def bfs(matrix, queue, visited \\ MapSet.new(), ways \\ []) do
    if :queue.is_empty(queue) or Enum.count(ways) != 0 do
      {queue, visited, ways}
    else
      {{:value, el}, queue} = :queue.out(queue)
      {{i,j}=point, depth} = el

      if matrix |> at(point) == ?E do
        IO.puts("Found new way of length #{depth}")
        {:queue.new(), visited, [depth | ways]}

      else
        neighbours =
          [{i+1, j}, {i-1, j}, {i, j+1}, {i, j-1}]
          |> Enum.filter(fn to -> not_visited(visited, to) and can_go?(matrix, point, to) end)

        visited =
          neighbours
          |> Enum.reduce(visited, fn to, visited -> MapSet.put(visited, to) end)
        queue =
          neighbours
          |> Enum.reduce(queue, fn to, queue ->  :queue.in({to, depth+1}, queue) end)

        # visualize(visited, queue, point)

        bfs(matrix, queue, visited, ways)
      end
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

  defp visualize(visited, queue, {i, j}) do
    field = 0..40 |> Enum.reduce([], fn _, acc ->
      acc ++ [(for _ <- 0..178, do: ".")]
    end)

    IO.write(IO.ANSI.clear)
    IO.puts("Go to (#{i};#{j}). Already visited #{visited |> MapSet.size}. Queued #{:queue.len(queue)}")

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

starts =
  for i <- 0..Enum.count(matrix)-1,
      j <- 0..Enum.count(Enum.at(matrix, 0))-1,
      Matrix.at(matrix, {i, j}) in [?a, ?S] do
        {i, j}
  end

starts
|> Enum.reduce([], fn start, acc ->
  {_, _, len} =  Matrix.bfs(matrix, :queue.in({start, 0}, :queue.new()))
  [len | acc]
end)
|> IO.inspect()

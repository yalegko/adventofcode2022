#!/usr/bin/env elixir

defmodule Field do
  def maxes(), do: {7, 5}
  # def maxes(), do: {101, 36}
  # def maxes(), do: {121, 26}
  def maxx(), do: maxes |> elem(0)
  def maxy(), do: maxes |> elem(1)

  # As winds do not interfere with each other -- they will cycle in pattern LCM(maxx, maxy).
  def cycle_len() do
    wind_x = maxx() - 1
    wind_y = maxy() - 1

    div(wind_x*wind_y, Integer.gcd(wind_x, wind_y))
  end

  def search(field, from, {x, y} = to) do
    fields = field |> precalc_fields()

    if fields[0] != fields[cycle_len()] do
      throw("Failed to find cycle in winds pattern")
    end
    cycle_len() |> IO.inspect(label: "Found a cycle with len")

    try do
      bfs(fields, [{from, 0}], {x, y - 1}, MapSet.new())
    catch
      msg when is_bitstring(msg)-> raise(msg)
      minute when is_integer(minute) -> minute
    end
  end

  def bfs(_fields, [] = _queue, _target, _seen) do
    throw("Failed to find the path!")
  end

  def bfs(fields, [h | tail] = _queue, target, seen) do
    {pos, minute} = h
    if pos == target, do: throw(minute)

    # IO.puts("Minute: #{minute}")
    round = rem(minute, cycle_len())
    moves =
      fields[round+1]
      # |> visualize(pos)
      |> possible_moves(pos)
      |> Enum.reject(fn pos -> seen |> MapSet.member?({pos, round}) end)
      # |> IO.inspect(label: "moves from #{inspect(pos)}")

    queue = moves |> Enum.map(&({&1, minute + 1}))
    seen = moves |> Enum.reduce(seen, &MapSet.put(&2, {&1, round}))

    # IO.puts("Round #{minute} seen #{MapSet.size(seen)} moves #{length(tail)}")

    bfs(fields, tail ++ queue, target, seen)
  end

  def possible_moves(field, {x, y}) do
    [
      {x, y + 1}, {x, y - 1}, {x - 1, y}, {x + 1, y},
    ]
    |> Enum.reject(fn {x, y} -> x <= 0 or x >= maxx() or y <= 0 or y >= maxy() end)
    |> Enum.concat([{x, y}]) # Stay as is.
    |> Enum.reject(fn pos -> field |> Map.has_key?(pos) end)
  end

  # We are going to precalculate all possible fields to use them in search.
  def precalc_fields(field) do
    fields = Map.put(
      %{},
      0,
      field |> Map.filter(fn {_, [v]} -> v in [">", "<", "^", "v"] end)
    )
    for round <- 1..cycle_len()+1, reduce: fields do
      fields -> fields |> Map.fetch!(round - 1) |> move() |> then(&Map.put(fields, round, &1))
    end
  end

  def field(fields, round) do
    {maxx, maxy} = maxes()
    lcm = div(maxx*maxy, Integer.gcd(maxx, maxy))

    fields[rem(round, lcm)]
  end

  def move(field) do
    maxes = maxes()

    for {pos, winds} <- field, wind <- winds, reduce: %{} do
      new_field ->
        new_field
        |> Map.update(
          pos |> move_wind(wind) |> wrap(maxes),
          [wind],
          fn old -> [wind | old] end
        )
    end
end

  def move_wind({x, y}, ">"), do: {x + 1, y}
  def move_wind({x, y}, "v"), do: {x, y + 1}
  def move_wind({x, y}, "<"), do: {x - 1, y}
  def move_wind({x, y}, "^"), do: {x, y - 1}

  # Walls are at x=0, y=0, x=maxx and y=maxy
  def wrap({0, y}, {maxx, _maxy}), do: {maxx-1, y}
  def wrap({x, 0}, {_maxx, maxy}), do: {x, maxy-1}
  def wrap({x, y}, {maxx, _maxy}) when x == maxx, do: {1, y}
  def wrap({x, y}, {_maxx, maxy}) when y == maxy, do: {x, 1}
  def wrap({x, y}, {_maxx, _maxy}), do: {x, y}

  def visualize(field, player) do
    {maxx, maxy} = maxes()

    to_print = field |> Map.put(player, ["@"])

    for(x <- 0..maxx, do: "#") |> Enum.join() |> IO.puts()
    for y <- 1..maxy-1 do
      for(x <- 1..maxx-1, do: {x, y})
      |> Enum.map(fn  pos -> Map.get(to_print, pos, ["."])  end)
      |> Enum.map(fn
        [c] -> c
        list -> length(list) |> Integer.to_string()
      end)
      |> Enum.join()
      |> then(&IO.puts("#" <> &1 <> "#"))
    end
    for(x <- 0..maxx, do: "#") |> Enum.join() |> IO.puts()

    IO.puts("")

    field
  end
end

[fname] = System.argv()

field =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.graphemes/1)
  |> Stream.with_index()
  |> Stream.scan(%{}, fn {row, y}, acc ->
    row
    |> Enum.with_index()
    |> Enum.reject(fn {c, _x} -> c == "#" end)
    |> Enum.reduce(acc, fn {c, x}, acc -> acc |> Map.put({x, y}, [c]) end)
  end)
  |> Stream.take(-1)
  |> Enum.at(0)

start =
  field
  |> Enum.find(fn {{_x, y}, c} -> y == 0 and c == ["."] end)
  |> elem(0)

finish =
  Field.maxes()
  |> then(fn {_, maxy} ->
    field |> Enum.find(fn {{_x, y}, c} -> y == maxy and c == ["."] end)
  end)
  |> elem(0)

IO.puts("Looking for a way from #{inspect(start)} to #{inspect(finish)}")
field |> Field.visualize(start)

field
|> Field.search(start, finish)
|> IO.inspect(label: "Arrived at minute")

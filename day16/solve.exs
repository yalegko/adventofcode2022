#!/usr/bin/env elixir

defmodule Valve do
  defstruct name: "", rate: 0, tunnels: []
end

defmodule Field do
  defstruct valves: Map.new()

  def add_valve(field, name: n, rate: r, tunnels: t) do
    %Field{
      field
      | valves:
          field.valves
          |> Map.put(n, %Valve{name: n, rate: r, tunnels: t})
    }
  end

  def search(field, distances, cur, unvisited, time_left) do
    unvisited
    |> Enum.filter(fn to -> distances[{cur, to}] < time_left end)
    |> Enum.map(fn to ->
      time_after_open = time_left - distances[{cur, to}] - 1

      field.valves[to].rate * time_after_open +
        search(field, distances, to, unvisited |> Enum.reject(&(&1 == to)), time_after_open)
    end)
    |> Enum.max(fn -> 0 end)
  end

  def search(_field, _distances, _cur, _unvisited, 0), do: 0
  def search(_field, _distances, _cur, [], _time_left), do: 0
end

[fname] = System.argv()

field =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, "; "))
  |> Stream.scan(
    struct(Field),
    fn
      [
        "Valve " <> <<name::bytes-size(2)>> <> " has flow rate=" <> rate,
        part2
      ],
      field ->
        tunnels =
          case part2 do
            "tunnel leads to valve " <> tunnel -> [tunnel]
            "tunnels lead to valves " <> tunnels -> tunnels |> String.split(", ")
          end

        field
        |> Field.add_valve(
          name: name,
          rate: String.to_integer(rate),
          tunnels: tunnels
        )
    end
  )
  |> Stream.take(-1)
  |> Enum.at(0)
  |> IO.inspect(label: "Field")

names =
  field.valves
  |> Enum.map(fn {name, _} -> name end)
  |> IO.inspect(label: "Names")

distances =
  for(a <- names, b <- field.valves[a].tunnels, do: {a, b})
  |> Enum.reduce(Map.new(), fn {a, b}, distances ->
    distances
    |> Map.put({a, a}, 0)
    |> Map.put({a, b}, 1)
  end)

distances =
  for(b <- names, a <- names, c <- names, do: {a, b, c})
  |> Enum.reduce(distances, fn {a, b, c}, distances ->
    old = Map.get(distances, {a, c}, 100_500)
    new = Map.get(distances, {a, b}, 100_500) + Map.get(distances, {b, c}, 100_500)

    Map.put(distances, {a, c}, min(old, new))
  end)

# |> IO.inspect()

distances
|> Enum.filter(fn {_dir, value} -> value > 99 end)
|> IO.inspect()

worth_visiting =
  field.valves
  |> Enum.filter(fn {_name, valve} -> valve.rate > 0 end)
  |> Enum.map(&elem(&1, 0))
  |> IO.inspect(label: "Worth visiting")

field
|> Field.search(distances, "AA", worth_visiting, 30)
|> IO.inspect()

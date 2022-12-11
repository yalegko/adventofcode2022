#!/usr/bin/env elixir

defmodule Rope do
  defstruct H: {0, 0}, T: {0, 0}

  def move(rope, dir, steps) do
    1..steps
    |> Enum.reduce({rope, []}, fn _, {rope, visited} ->
      moved_rope =
        rope
        |> step_head(dir)
        |> adjust_tail

      {moved_rope, [moved_rope."T" | visited]}
    end)
  end

  def step_head(%Rope{H: {hx, hy}} = rope, "R"), do: %Rope{rope | H: {hx + 1, hy}}
  def step_head(%Rope{H: {hx, hy}} = rope, "L"), do: %Rope{rope | H: {hx - 1, hy}}
  def step_head(%Rope{H: {hx, hy}} = rope, "U"), do: %Rope{rope | H: {hx, hy + 1}}
  def step_head(%Rope{H: {hx, hy}} = rope, "D"), do: %Rope{rope | H: {hx, hy - 1}}

  def adjust_tail(%Rope{H: {hx, hy}, T: {tx, ty}} = rope) do
    cond do
      hx == tx and hy == ty + 2 -> %Rope{rope | T: {tx, ty + 1}}
      hx == tx and hy == ty - 2 -> %Rope{rope | T: {tx, ty - 1}}
      hy == ty and hx == tx + 2 -> %Rope{rope | T: {tx + 1, ty}}
      hy == ty and hx == tx - 2 -> %Rope{rope | T: {tx - 1, ty}}
      hx == tx + 1 and hy == ty + 2 -> %Rope{rope | T: {tx + 1, ty + 1}}
      hx == tx + 2 and hy == ty + 1 -> %Rope{rope | T: {tx + 1, ty + 1}}
      hx == tx + 1 and hy == ty - 2 -> %Rope{rope | T: {tx + 1, ty - 1}}
      hx == tx + 2 and hy == ty - 1 -> %Rope{rope | T: {tx + 1, ty - 1}}
      hx == tx - 1 and hy == ty - 2 -> %Rope{rope | T: {tx - 1, ty - 1}}
      hx == tx - 2 and hy == ty - 1 -> %Rope{rope | T: {tx - 1, ty - 1}}
      hx == tx - 1 and hy == ty + 2 -> %Rope{rope | T: {tx - 1, ty + 1}}
      hx == tx - 2 and hy == ty + 1 -> %Rope{rope | T: {tx - 1, ty + 1}}
      true -> rope
    end
  end
end

[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split/1)
|> Stream.map(fn [dir, step] -> {dir, String.to_integer(step)} end)
|> Stream.scan({struct!(Rope), []}, fn {dir, step}, {rope, visited} ->
  {moved_rope, just_visited} =
    rope
    |> Rope.move(dir, step)

  {moved_rope, visited ++ just_visited}
end)
|> Stream.take(-1)
|> Enum.flat_map(&elem(&1, 1))
|> Enum.map(&IO.inspect/1)
|> Enum.uniq()
|> Enum.map(&IO.inspect/1)
|> Enum.count()
|> IO.inspect()

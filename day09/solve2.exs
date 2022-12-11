#!/usr/bin/env elixir

defmodule Rope do
  defstruct H: {0, 0}, T: {0, 0}

  def step_head(%Rope{H: {hx, hy}} = rope, "R"), do: %Rope{rope | H: {hx + 1, hy}}
  def step_head(%Rope{H: {hx, hy}} = rope, "L"), do: %Rope{rope | H: {hx - 1, hy}}
  def step_head(%Rope{H: {hx, hy}} = rope, "U"), do: %Rope{rope | H: {hx, hy + 1}}
  def step_head(%Rope{H: {hx, hy}} = rope, "D"), do: %Rope{rope | H: {hx, hy - 1}}

  def adjust_tail(%Rope{H: {hx, hy}, T: {tx, ty}} = rope) do
    dx = hx - tx
    dy = hy - ty
    dist = dx * dx + dy * dy

    cond do
      dist in [0, 1, 1 * 1 + 1 * 1] ->
        rope

      dist in [2 * 2 + 0, 2 * 2 + 1 * 1, 2 * 2 + 2 * 2] ->
        %Rope{rope | T: {tx + sign(dx), ty + sign(dy)}}
    end
  end

  defp sign(x) when x > 0, do: 1
  defp sign(x) when x < 0, do: -1
  defp sign(x) when x == 0, do: 0
end

defmodule Chain do
  defstruct links: [], visited: MapSet.new()

  def new(len), do: %Chain{links: Enum.map(1..len, fn _ -> {0, 0} end)}

  def move(chain, dir, steps) do
    for _i <- 1..steps, reduce: chain do
      %Chain{links: links, visited: visited} ->
        # Do the step with a head.
        [h | rest] = links
        %Rope{H: new_h} = %Rope{H: h, T: {0, 0}} |> Rope.step_head(dir)
        links = [new_h | rest]

        # Adjust all links to the new position.
        {links, _} =
          links
          |> Enum.map_reduce(:head, fn
            link, :head ->
              {link, link}

            link, prev ->
              %Rope{T: new_link} = %Rope{H: prev, T: link} |> Rope.adjust_tail()
              {new_link, new_link}
          end)

        # IO.inspect(links, label: "#{dir} #{i}/#{steps}")
        %Chain{links: links, visited: MapSet.put(visited, Enum.at(links, -1))}
    end
  end
end

[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split/1)
|> Stream.map(fn [dir, step] -> {dir, String.to_integer(step)} end)
|> Stream.scan(
  Chain.new(10),
  fn {dir, step}, chain -> chain |> Chain.move(dir, step) end
)
|> Stream.take(-1)
|> Enum.at(0)
|> Map.fetch!(:visited)
|> MapSet.size()
|> IO.inspect()

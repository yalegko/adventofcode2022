#!/usr/bin/env elixir

defmodule CRT do
  def update_line(line, pc, x) do
    pos = rem(pc - 1, 40)

    if x - 1 <= pos and pos <= x + 1 do
      List.replace_at(line, pos, "#")
    else
      line
    end
  end

  def mb_display(line, pc) do
    if rem(pc, 40) == 0 do
      line |> Enum.join() |> IO.puts()
      empty()
    else
      line
    end
  end

  def empty(), do: 0..39 |> Enum.map(fn _ -> " " end)
end

[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.trim/1)
|> Stream.scan({0, 1, CRT.empty()}, fn cmd, {pc, x, crt_line} ->
  {new_pc, new_x} =
    case cmd do
      "noop" -> {pc + 1, x}
      "addx " <> v -> {pc + 2, x + String.to_integer(v)}
    end

  new_line =
    for pc <- (pc + 1)..new_pc, reduce: crt_line do
      crt_line ->
        crt_line
        |> CRT.update_line(pc, x)
        |> CRT.mb_display(pc)
    end

  {new_pc, new_x, new_line}
end)
|> Stream.run()

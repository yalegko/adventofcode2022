#!/usr/bin/env elixir

[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split/1)
|> Stream.scan({0, 1, []}, fn cmd, {pc, x, signals} ->
  {new_pc, new_x} =
    case cmd do
      ["noop"] -> {pc + 1, x}
      ["addx", v] -> {pc + 2, x + String.to_integer(v)}
    end

  signals =
    (pc + 1)..new_pc
    |> Enum.reduce(signals, fn pc, signals ->
      cond do
        rem(pc - 20, 40) == 0 -> [pc * x | signals]
        true -> signals
      end
    end)

  IO.inspect({new_pc, cmd, new_x, signals})
  {new_pc, new_x, signals}
end)
|> Stream.take(-1)
|> Enum.at(0)
|> IO.inspect()
|> elem(2)
|> Enum.reduce(&+/2)
|> IO.inspect()

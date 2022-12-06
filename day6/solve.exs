#!/bin/env elixir

[fname] = System.argv()

File.stream!(fname, [], 1)
|> Stream.chunk_every(4, 1)
|> Stream.with_index(1)
|> Stream.transform(0, fn {chunk, i}, _acc ->
  num_uniq_chars =
    chunk
    |> MapSet.new()
    |> MapSet.size()

  case num_uniq_chars do
    4 -> {:halt, 0}
    _ -> {[i], 0}
  end
end)
|> Stream.take(-1)
|> Enum.map(&(&1 + 4))
|> Enum.each(&IO.inspect/1)

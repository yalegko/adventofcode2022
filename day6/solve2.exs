#!/bin/env elixir

chunk_size = 14

[fname] = System.argv()

# Read in a sliding window of a `chunk_size`.
File.stream!(fname, [], 1)
|> Stream.chunk_every(chunk_size, 1)
|> Stream.with_index(1)

# Find the first one with all distinct chars.
|> Stream.transform(0, fn {chunk, i}, _acc ->
  num_uniq_chars =
    chunk
    |> MapSet.new()
    |> MapSet.size()

  case num_uniq_chars do
    ^chunk_size -> {:halt, 0}
    _ -> {[i], 0}
  end
end)

# Pretty print the result.
|> Stream.take(-1)
|> Enum.map(&(&1 + chunk_size))
|> Enum.each(&IO.inspect/1)

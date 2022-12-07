#!/usr/bin/env elixir

[fname] = System.argv()
file = File.stream!(fname)

# Form the initial stacks value.
stacks =
  file
  |> Enum.take_while(&String.contains?(&1, "["))

  # To pairs `{X, i}` where `i` is a number of stack.
  |> Enum.map(fn line ->
    line
    |> String.graphemes()
    |> Enum.chunk_every(4)
    |> Enum.with_index(1)
    |> Enum.filter(fn {stage, _i} ->
      List.first(stage) == "["
    end)
    |> Enum.map(fn {stage, i} ->
      [_, letter | _] = stage
      {i, letter}
    end)
  end)

  # Collect the stacks themself.
  |> Enum.reduce(%{}, fn stacks_stage, stacks ->
    stacks_stage
    |> Enum.reduce(stacks, fn {i, block}, stacks ->
      if Map.has_key?(stacks, i) do
        Map.update!(stacks, i, fn old -> old ++ [block] end)
      else
        Map.put(stacks, i, [block])
      end
    end)
  end)

# "move 14 from 4 to 5"
command_regex = ~r/^move (\d+) from (\d+) to (\d+)$/

# Skip until the commands.
file
|> Stream.drop_while(fn line -> not String.contains?(line, "move") end)

# Parse them
|> Stream.map(&String.trim/1)
|> Stream.map(fn line ->
  Regex.run(command_regex, line)
  # 0th is not a group.
  |> Enum.drop(1)
  |> Enum.map(&String.to_integer/1)
end)

# Process the commands.
|> Stream.scan(stacks, fn [amount, from, to], stacks ->
  {taken, rest} = Enum.split(stacks[from], amount)

  stacks
  |> Map.put(from, rest)
  |> Map.put(to, taken ++ stacks[to])
end)

# Print final state.
|> Stream.take(-1)
|> Stream.each(&IO.inspect/1)

# Pretty print the result.
|> Stream.map(fn stacks ->
  stacks
  |> Enum.sort(fn {idx1, _stack}, {idx2, _stack2} -> idx1 <= idx2 end)
  |> Enum.map(fn {_idx, stack} -> List.first(stack) end)
  |> Enum.join("")
end)
|> Stream.each(&IO.inspect/1)
|> Stream.run()

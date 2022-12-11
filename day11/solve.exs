#!/usr/bin/env elixir

defmodule Monkey do
  defstruct items: [], operation: nil, divisor: 0, targets: {}

  def new(lines) do
    items =
      lines
      |> Enum.at(1)
      |> String.replace_prefix("Starting items: ", "")
      |> String.replace(",", " ")
      |> String.split()
      |> Enum.map(&String.to_integer/1)

    opeartion =
      lines
      |> Enum.at(2)
      |> String.replace_prefix("Operation: new = ", "")

    divisor =
      lines
      |> Enum.at(3)
      |> String.replace_prefix("Test: divisible by ", "")
      |> String.to_integer()

    to_true =
      lines
      |> Enum.at(4)
      |> String.replace_prefix("If true: throw to monkey ", "")
      |> String.to_integer()

    to_false =
      lines
      |> Enum.at(5)
      |> String.replace_prefix("If false: throw to monkey ", "")
      |> String.to_integer()

    %Monkey{items: items, operation: opeartion, divisor: divisor, targets: {to_true, to_false}}
  end

  def throw(monkeys, i) do
    monkey = monkeys |> Enum.at(i)
    [item | rest] = monkey.items

    new_item =
      monkey.operation
      |> Code.eval_string([old: item])
      |> elem(0)
      |> div(3)

    target_idx =
      monkey.targets
      |> elem(
        if rem(new_item, monkey.divisor) == 0, do: 0, else: 1
      )

    monkeys
    |> List.replace_at(i, %Monkey{monkey | items: rest})
    |> List.update_at(target_idx, fn m -> %Monkey{m | items: m.items ++ [new_item]} end)
  end
end

[fname] = System.argv()

monkeys =
  File.stream!(fname)
  |> Stream.map(&String.trim/1)
  |> Stream.chunk_every(6, 7)
  |> Enum.map(fn chunk -> Monkey.new(chunk) end)
  |> IO.inspect()


1..20
|> Enum.reduce({monkeys, %{}}, fn round, {monkeys, throws} ->
  IO.inspect(round, label: "ROUND")

  0..Enum.count(monkeys) - 1
  |> Enum.reduce({monkeys, throws}, fn i, {monkeys, throws} ->
    num_throws =
      monkeys
      |> Enum.at(i)
      |> Map.get(:items)
      |> Enum.count()

    monkeys = case num_throws do
      0 -> monkeys
      n -> for _ <- 1..n, reduce: monkeys do monkeys -> Monkey.throw(monkeys, i) end
    end

    {
      monkeys,
      Map.update(throws, i, num_throws, &(&1 + num_throws))
    }
  end)
  |> IO.inspect()
end)
|> elem(1)
|> Enum.sort(fn {_name1, size1}, {_name2, size2} -> size1 <= size2 end)
|> Enum.take(-2)
|> Enum.reduce(1, fn {_k, v}, acc -> acc * v end)
|> IO.inspect()

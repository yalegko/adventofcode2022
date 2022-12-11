#!/usr/bin/env elixir

defmodule Monkey do
  defstruct items: [], operation: nil, divisor: 0, to_true: nil, to_false: nil

  def new(lines) do
    lines
    |> Enum.map(&String.split/1)
    |> Enum.reduce(struct!(Monkey), fn
      ["Monkey", _num], monkey ->
        monkey

      ["Starting", "items:" | items], monkey ->
        items
        |> Enum.map(fn s -> String.replace(s, ",", "") end)
        |> Enum.map(&String.to_integer/1)
        |> (fn items -> Map.put(monkey, :items, items) end).()

      ["Operation:", "new", "=" | operands], monkey ->
        Map.put(monkey, :operation, Enum.join(operands, " "))

      ["Test:", "divisible", "by", divisor], monkey ->
        Map.put(monkey, :divisor, String.to_integer(divisor))

      ["If", "true:", "throw", "to", "monkey", num], monkey ->
        Map.put(monkey, :to_true, String.to_integer(num))

      ["If", "false:", "throw", "to", "monkey", num], monkey ->
        Map.put(monkey, :to_false, String.to_integer(num))
    end)
  end

  def throw(monkeys, i, mod) do
    monkey = monkeys |> Enum.at(i)
    [item | rest] = monkey.items

    new_item =
      monkey.operation
      |> Code.eval_string(old: item)
      |> elem(0)
      |> rem(mod)

    target_idx = if rem(new_item, monkey.divisor) == 0, do: monkey.to_true, else: monkey.to_false

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
  |> IO.inspect(charlists: :as_lists)

module =
  monkeys
  |> Enum.reduce(1, fn m, acc -> acc * m.divisor end)

1..10000
|> Enum.reduce({monkeys, %{}}, fn round, {monkeys, throws} ->
  {monkeys, throws} =
    0..(Enum.count(monkeys) - 1)
    |> Enum.reduce({monkeys, throws}, fn i, {monkeys, throws} ->
      num_throws =
        monkeys
        |> Enum.at(i)
        |> Map.get(:items)
        |> Enum.count()

      monkeys =
        case num_throws do
          0 ->
            monkeys

          n ->
            for _ <- 1..n, reduce: monkeys do
              monkeys -> Monkey.throw(monkeys, i, module)
            end
        end

      {
        monkeys,
        Map.update(throws, i, num_throws, &(&1 + num_throws))
      }
    end)

  if rem(round, 1000) == 0,
    do: IO.inspect(throws, label: "ROUND #{round}")

  {monkeys, throws}
end)
|> elem(1)
|> Enum.sort(fn {_k1, n1}, {_k2, n2} -> n1 <= n2 end)
|> Enum.take(-2)
|> Enum.reduce(1, fn {_k, v}, acc -> acc * v end)
|> IO.inspect(label: "\nAnswer:")

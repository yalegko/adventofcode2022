#!/usr/bin/env elixir

defmodule MyList do
  def move(list, orig_i) do
    i = list |> Enum.find_index(fn {_v, i} -> i == orig_i end)

    {head, [{v, _} | tail]} = list |> Enum.split(i)

    n = length(list) - 1

    new_pos =
      case rem(i + v, n) do
        idx when idx >= 0 -> idx
        idx when idx < 0 -> idx + n
      end

    (head ++ tail)
    |> List.insert_at(new_pos, {v, orig_i})
  end
end

[fname] = System.argv()

list =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.to_integer/1)
  |> Stream.map(&(&1 * 811_589_153))
  |> Enum.with_index()
  |> Enum.to_list()

decrypted =
  for round <- 1..10, reduce: list do
    list ->
      for i <- 0..(length(list) - 1), reduce: list do
        list -> list |> MyList.move(i)
      end
  end
  |> Enum.map(fn {v, _i} -> v end)
  |> IO.inspect()

z_pos =
  decrypted
  |> Enum.find_index(&(&1 == 0))
  |> IO.inspect(label: "zero")

[1000, 2000, 3000]
|> Enum.map(&(&1 + z_pos))
|> Enum.map(&rem(&1, length(decrypted)))
|> Enum.map(&(decrypted |> Enum.at(&1)))
|> IO.inspect()
|> Enum.reduce(&+/2)
|> IO.inspect()

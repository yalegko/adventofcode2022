#!/usr/bin/env elixir

defmodule CMP do
  def less?(a, a) when is_integer(a), do: :equal
  def less?(a, b) when is_integer(a) and is_integer(b), do: a < b

  def less?([a | aa] = t1, [b | bb] = t2) do
    case less?(a, b) do
      :equal -> less?(aa, bb)
      res -> res
    end
  end

  def less?([], [_b | _]), do: true
  def less?([_a | _], []), do: false
  def less?([], []), do: :equal

  def less?(a, b) when is_integer(a) and is_list(b), do: less?([a], b)
  def less?(a, b) when is_list(a) and is_integer(b), do: less?(a, [b])
end

[fname] = System.argv()

fname
|> File.stream!()
|> Stream.map(&String.trim/1)
|> Stream.reject(&(&1 == ""))
|> Stream.map(&Code.eval_string/1)
|> Stream.map(&(&1 |> elem(0)))
|> Stream.chunk_every(2)
|> Stream.with_index(1)
|> Stream.filter(fn {[a, b], _i} -> CMP.less?(a, b) === true end)
|> Stream.each(&IO.inspect(&1, label: ">"))
|> Stream.map(fn {_pair, i} -> i end)
|> Stream.scan(0, &+/2)
|> Stream.take(-1)
|> Stream.each(&IO.inspect(&1, label: "Result"))
|> Stream.run()

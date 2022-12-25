#!/usr/bin/env elixir

defmodule SNAFU do
  def from(snafu) do
    snafu
    |> String.graphemes()
    |> Enum.reduce(0, fn c, acc -> acc * 5 + val(c) end)
  end

  def to(val) when val < 5 do
    char(val)
  end

  def to(val) do
    mod =
      case rem(val, 5) do
        mod when mod <= 2 -> mod
        mod when mod > 2 -> mod - 5
      end

    next = div(val - mod, 5)
    to(next) <> char(mod)
  end

  defp val("="), do: -2
  defp val("-"), do: -1
  defp val("0"), do: 0
  defp val("1"), do: 1
  defp val("2"), do: 2

  defp char(digit), do: ["=", "-", "0", "1", "2"] |> Enum.find(&(digit == val(&1)))
end

[fname] = System.argv()

fname
|> File.stream!()
|> Stream.map(&String.trim/1)
|> Stream.map(&SNAFU.from/1)
|> Stream.scan(fn num, acc -> acc + num end)
|> Stream.take(-1)
|> Enum.at(0)
|> IO.inspect()
|> SNAFU.to()
|> IO.inspect()

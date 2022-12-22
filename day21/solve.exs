#!/usr/bin/env elixir

defmodule Eval do
  def eval(code, term) do
    expr = Map.fetch!(code, term)

    case String.split(expr) do
      [op1, op, op2] -> do_op(eval(code, op1), op, eval(code, op2))
      [term] -> String.to_integer(term)
    end
  end

  def do_op(op1, "+", op2), do: op1 + op2
  def do_op(op1, "*", op2), do: op1 * op2
  def do_op(op1, "-", op2), do: op1 - op2
  def do_op(op1, "/", op2), do: div(op1, op2)
end

[fname] = System.argv()

code =
  fname
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&(String.split(&1, ": ")))
  |> Stream.scan(%{}, fn [name, expr], acc -> Map.put(acc, name, expr) end)
  |> Stream.take(-1)
  |> Enum.at(0)
  |> IO.inspect(label: "code")

code
|> Eval.eval("root")
|> IO.inspect()

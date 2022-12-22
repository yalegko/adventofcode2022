#!/usr/bin/env elixir

defmodule Eval do
  def precompile(code, "humn") do
    {:volatile, code}
  end

  def precompile(code, term) do
    case code|> Map.fetch!(term) |> String.split() do
      [v] -> {:stable, Map.put(code, term, do_eval(code, v))}

      [op1, _, op2] ->
        {vol1?, code} = precompile(code, op1)
        {vol2?, code} = precompile(code, op2)

        case {vol1?, vol2?} do
          {:volatile, _} -> {:volatile, code}
          {_, :volatile} -> {:volatile, code}
          {_, _} -> {
            :stable,
            code
            |> Map.put(term, eval(code, term))
            |> Map.drop([op1, op2])
          }
        end
    end
  end

  def solve(code, expr, res) do
    IO.inspect(label: "Expecting #{expr} == #{res}")

    case String.split(expr) do
      ["humn"] -> res
      [term] -> solve(code, Map.fetch!(code, term), res)

      [op1, op, op2] ->
        {vol, const} =
          code
          |> get_volatile(op1, op2)

        case [op1, op, op2] do
          [_, "+", _] -> solve(code, vol, res - eval(code, const))
          [_, "*", _] -> solve(code, vol, res / eval(code, const))

          [^vol, "-", ^const] -> solve(code, vol, res + eval(code, const))
          [^const, "-", ^vol] -> solve(code, vol, eval(code, const) - res)

          [^vol, "/", ^const] -> solve(code, vol, res * eval(code, const))
          [^const, "/", ^vol] -> solve(code, vol, eval(code, const) / res)
        end
    end
  end

  def get_volatile(code, op1, op2) do
    case {Map.get(code, op1), Map.get(code, op2)} do
      {v1, v2} when is_binary(v1) -> {op1, op2}
      {v1, v2} when is_binary(v2) -> {op2, op1}
    end
  end

  def eval(code, term) do
    do_eval(code, Map.fetch!(code, term))
  end

  def do_eval(code, expr) when is_binary(expr) do
    case String.split(expr) do
      [v] -> String.to_integer(v)
      [op1, op, op2] -> do_op(eval(code, op1), op, eval(code, op2))
    end
  end

  # Precompiled.
  def do_eval(code, value) when is_float(value), do:   value
  def do_eval(code, value) when is_integer(value), do:   value

  def do_op(op1, "==", op2), do: op1 == op2
  def do_op(op1, "+", op2), do: op1 + op2
  def do_op(op1, "*", op2), do: op1 * op2
  def do_op(op1, "-", op2), do: op1 - op2
  def do_op(op1, "/", op2), do: op1 / op2
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
  |> then(&(IO.inspect(&1, label: "Code. Size #{map_size(&1)}")))

compiled =
  code
  |> Map.update!("root", fn old ->
    [op1, _, op2] = old |> String.split()
    op1  <> " == " <> op2
  end)
  |> Eval.precompile("root")
  |> elem(1)
  |> then(&(IO.inspect(&1, label: "Compiled. Size #{map_size(&1)}")))

[op1, _, op2] = Map.fetch!(compiled, "root") |> String.split() |> IO.inspect()

{volatile, const} = Eval.get_volatile(compiled, op1, op2)
  |> IO.inspect(label: "volitile part")

res =
  compiled
  |> Map.put("humn", "???")
  |> Eval.solve(volatile, Eval.eval(compiled, const))
  |> IO.inspect()

code
|> Map.put("humn", Float.to_string(res))

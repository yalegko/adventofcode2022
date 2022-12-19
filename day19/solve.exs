#!/usr/bin/env elixir

defmodule BP do
  defstruct ore_robo: -1, clay_robo: -1, obs_robo: {-1, -1}, geode_robo: {-1, -1}

  def new(), do: struct!(BP)

  def set_ore(bp, oress), do: %BP{bp | ore_robo: oress}
  def set_clay(bp, oress), do: %BP{bp | clay_robo: oress}
  def set_obsidian(bp, oress, clay), do: %BP{bp | obs_robo: {oress, clay}}
  def set_geode(bp, oress, obsidian), do: %BP{bp | geode_robo: {oress, obsidian}}

  def max(bp, :ore),
    do: [bp.ore_robo, bp.clay_robo, elem(bp.obs_robo, 0), elem(bp.geode_robo, 0)] |> Enum.max()

  def max(bp, :clay), do: elem(bp.obs_robo, 1)
  def max(bp, :obsidian), do: elem(bp.geode_robo, 1)
  def max(bp, :geode), do: 100_500
end

defmodule GameState do
  defstruct ores: %{}, robots: %{}

  def new(),
    do: %GameState{
      ores: %{ore: 0, clay: 0, obsidian: 0, geode: 0},
      robots: %{ore: 1, clay: 0, obsidian: 0, geode: 0}
    }

  def produce(%GameState{ores: ores, robots: robots} = state) do
    %GameState{
      state
      | ores: %{
          ore: ores.ore + robots.ore,
          clay: ores.clay + robots.clay,
          obsidian: ores.obsidian + robots.obsidian,
          geode: ores.geode + robots.geode
        }
    }
  end

  def out_of_ores?(state) do
    state.ores |> Enum.any?(fn {_type, amount} -> amount < 0 end)
  end

  def enough_robots?(_state, _bp, :wait), do: false
  def enough_robots?(state, bp, type), do: state.robots[type] >= BP.max(bp, type)

  def start_building(state, _bp, :wait) do
    state
  end

  def start_building(%GameState{ores: ores} = state, bp, :ore) do
    %GameState{
      state
      | ores:
          ores
          |> Map.update!(:ore, fn v -> v - bp.ore_robo end)
    }
  end

  def start_building(%GameState{ores: ores} = state, bp, :clay) do
    %GameState{
      state
      | ores:
          ores
          |> Map.update!(:ore, fn v -> v - bp.clay_robo end)
    }
  end

  def start_building(%GameState{ores: ores} = state, bp, :obsidian) do
    {ore, clay} = bp.obs_robo

    %GameState{
      state
      | ores:
          ores
          |> Map.update!(:ore, fn v -> v - ore end)
          |> Map.update!(:clay, fn v -> v - clay end)
    }
  end

  def start_building(%GameState{ores: ores} = state, bp, :geode) do
    {ore, obsidian} = bp.geode_robo

    %GameState{
      state
      | ores:
          ores
          |> Map.update!(:ore, fn v -> v - ore end)
          |> Map.update!(:obsidian, fn v -> v - obsidian end)
    }
  end

  def add_robo(state, :wait) do
    state
  end

  def add_robo(%GameState{robots: robots} = state, type) do
    %GameState{state | robots: Map.update!(robots, type, fn v -> v + 1 end)}
  end
end

defmodule Game do
  use Agent

  def new_cache() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def run_simultaion(bp) do
    Agent.update(__MODULE__, fn _ -> %{} end)

    simualate(bp, GameState.new(), 1)
  end

  def simualate(_bp, state, 25) do
    state
    |> Map.get(:ores)
    |> Map.get(:geode)
  end

  def simualate(bp, state, time) do
    key = {
      state.robots,
      [:ore, :clay, :obsidian, :geode]
      |> Enum.map(fn t ->
        if GameState.enough_robots?(state, bp, t), do: -1, else: state.ores[t]
      end)
    }

    {stime, smax} = Agent.get(__MODULE__, &Map.get(&1, key, {nil, 0}))

    if stime != nil and stime <= time do
      smax
    else
      max =
        [:wait, :ore, :clay, :obsidian, :geode]
        |> Enum.reverse()
        |> Enum.reject(fn robo -> state |> GameState.enough_robots?(bp, robo) end)
        |> Enum.map(fn robo -> {robo, state |> GameState.start_building(bp, robo)} end)
        |> Enum.reject(fn {_, state} -> state |> GameState.out_of_ores?() end)
        |> Enum.map(fn {robo, state} -> {robo, state |> GameState.produce()} end)
        |> Enum.map(fn {robo, state} -> state |> GameState.add_robo(robo) end)
        |> Enum.map(fn state -> simualate(bp, state, time + 1) end)
        |> Enum.max()

      Agent.update(__MODULE__, &Map.put(&1, key, {time, max}))

      max
    end
  end

  def map() do
    Agent.get(__MODULE__, & &1)
  end
end

[fname] = System.argv()

blueprints =
  fname
  |> File.stream!()
  |> Stream.map(fn line -> line |> String.split(": ") |> Enum.at(1) end)
  |> Stream.map(fn line -> line |> String.split(". ") end)
  |> Stream.map(fn
    [
      "Each ore robot costs " <> ore,
      "Each clay robot costs " <> clay,
      "Each obsidian robot costs " <> obsidian,
      "Each geode robot costs" <> jeode
    ] ->
      [ore, clay, obsidian, jeode]
      |> Enum.map(&String.split/1)
  end)
  |> Stream.map(fn
    [
      [ore_ore, "ore"],
      [clay_ore, "ore"],
      [obs_ore, "ore", "and", obs_clay, "clay"],
      [geo_ore, "ore", "and", geo_obs, "obsidian."]
    ] ->
      BP.new()
      |> BP.set_ore(ore_ore |> String.to_integer())
      |> BP.set_clay(clay_ore |> String.to_integer())
      |> BP.set_obsidian(obs_ore |> String.to_integer(), obs_clay |> String.to_integer())
      |> BP.set_geode(geo_ore |> String.to_integer(), geo_obs |> String.to_integer())
  end)
  |> Enum.to_list()
  |> IO.inspect()

Game.new_cache()

blueprints
# |> Enum.take(1)
|> Enum.map(&Game.run_simultaion/1)
|> Enum.with_index(1)
|> IO.inspect()
|> Enum.reduce(0, fn {v, i}, acc -> acc + i * v end)
|> IO.inspect()

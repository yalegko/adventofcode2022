#!/usr/bin/env elixir

defmodule BP do
  def new(), do: %{}

  def add(bp, robo_type, cost_map),
    do: bp |> Map.put(robo_type, Map.merge(%{ore: 0, clay: 0, obsidian: 0}, cost_map))

  def max(bp, ore_type),
    do: bp |> Enum.map(fn {_, cost} -> cost[ore_type] end) |> Enum.max()
end

defmodule GameState do
  defstruct ores: %{}, robots: %{}

  def new(),
    do: %GameState{
      ores: %{ore: 0, clay: 0, obsidian: 0, geode: 0},
      robots: %{ore: 1, clay: 0, obsidian: 0, geode: 0}
    }

  def produce(%GameState{ores: ores, robots: robots} = state),
    do: %GameState{state | ores: Map.merge(ores, robots, fn _k, v1, v2 -> v1 + v2 end)}

  def out_of_ores?(state),
    do: state.ores |> Enum.any?(fn {_type, amount} -> amount < 0 end)

  def enough_robots?(_state, _bp, :wait), do: false
  def enough_robots?(state, bp, type), do: state.robots[type] >= BP.max(bp, type)

  def start_building(state, _bp, :wait),
    do: state

  def start_building(%GameState{ores: ores} = state, bp, type),
    do: %GameState{state | ores: Map.merge(ores, bp[type], fn _k, v1, v2 -> v1 - v2 end)}

  def add_robo(state, :wait),
    do: state

  def add_robo(state, type),
    do: %GameState{state | robots: Map.update!(state.robots, type, &(&1 + 1))}
end

defmodule Game do
  use Agent

  def run_simultaion(bp) do
    # As we are going to process each blueprint in its own process, it seems ok to create a
    # separate cache per instance (we have just 2-3 of them here?).
    {:ok, cache} = Agent.start_link(fn -> %{} end)

    simualate(cache, bp, GameState.new(), 1)
  end

  def simualate(_, _, state, 33) do
    state.ores.geode
  end

  def simualate(cache, bp, state, time) do
    # The main idea is to cache function results. We can't just rely on the number of robots we
    # have, as we'll lose all the states where we are hoarding resources waiting for a better move.
    #
    # Storing resources as a key won't help as well. So here we distinguish "collecting resource X"
    # and "we have enough of resource X". That way we don't care about any differences of unimportant
    # recources levels, but keep an amount of important ones.
    key = {
      state.robots,
      for t <- [:ore, :clay, :obsidian] do
        if GameState.enough_robots?(state, bp, t), do: -1, else: state.ores[t]
      end
    }

    # Another "hack" is to use global state to memoize the function results.
    {stime, smax} = Agent.get(cache, &Map.get(&1, key, {nil, 0}))

    # If we've already seen such key-state we don't need to proceed unless we faced it at an earlier time.
    if stime != nil and stime <= time do
      smax
    else
      # Choose between all possible ways to spend time. Prefer more profitable ones.
      lmax =
        [:wait, :ore, :clay, :obsidian, :geode]
        |> Enum.reverse()

        # Do not build excess robots, it the production level for the ore already covers the most
        # expensive robot to be built in one turn.
        |> Enum.reject(fn robo -> state |> GameState.enough_robots?(bp, robo) end)

        # Select only those moves which we could afford right now.
        |> Enum.map(fn robo -> {robo, state |> GameState.start_building(bp, robo)} end)
        |> Enum.reject(fn {_, state} -> state |> GameState.out_of_ores?() end)

        # Do the production before adding a freshly-built robot!
        |> Enum.map(fn {robo, state} -> {robo, state |> GameState.produce()} end)
        |> Enum.map(fn {robo, state} -> state |> GameState.add_robo(robo) end)

        # Then recurse and find maximum over all possible moves.
        |> Enum.map(fn state -> simualate(cache, bp, state, time + 1) end)
        |> Enum.max()

      # Store found maximum in a global state alongside its time (we could face same state earlier in the game).
      Agent.update(cache, &Map.put(&1, key, {time, lmax}))

      lmax
    end
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
      "Each geode robot costs" <> geode
    ] ->
      [ore, clay, obsidian, geode]
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
      |> BP.add(:ore, %{ore: ore_ore |> String.to_integer()})
      |> BP.add(:clay, %{ore: clay_ore |> String.to_integer()})
      |> BP.add(:obsidian, %{
        ore: obs_ore |> String.to_integer(),
        clay: obs_clay |> String.to_integer()
      })
      |> BP.add(:geode, %{
        ore: geo_ore |> String.to_integer(),
        obsidian: geo_obs |> String.to_integer()
      })
  end)
  |> Enum.to_list()
  |> Enum.take(3)
  |> IO.inspect()

blueprints
# |> Enum.map(&Game.run_simultaion/1)
# |> IO.inspect()
# |> Enum.reduce(&*/2)
|> Task.async_stream(&Game.run_simultaion/1, timeout: :infinity)
|> Enum.reduce(1, fn {:ok, max}, acc -> acc * max end)
|> IO.inspect()

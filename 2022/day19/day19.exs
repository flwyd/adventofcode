#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/19

defmodule Day19 do
  @moduledoc """
  Input is lines describing a blueprint of resource requirements for a factory
  to build four types of robots: ore, clay, obsidian, and geode.  All robots of
  a given type take the same types of resources (everything needs ore, obsidian
  needs clay, geode needs obsidian) and differ in the amount needed.
  The factory can make one robot per minute, each robot produces one of its type
  of resource each minute, starting one minute after creation.  Problems focus
  on the maximum number of geodes a blueprint can produce.
  """

  defmodule State do
    defstruct robots: %{ore: 1, clay: 0, obsidian: 0, geode: 0},
              resources: %{ore: 0, clay: 0, obsidian: 0, geode: 0}

    def score(state), do: state.resources.geode

    def build(state, type, cost) do
      struct!(state,
        robots: Map.update!(state.robots, type, &(&1 + 1)),
        resources: Map.merge(state.resources, cost, fn _k, v1, v2 -> v1 - v2 end)
      )
    end

    def can_build?(state, cost), do: Enum.all?(cost, fn {k, v} -> v <= state.resources[k] end)

    def add_resources(state, res),
      do: struct!(state, resources: Map.merge(state.resources, res, fn _k, v1, v2 -> v1 + v2 end))

    def all_possible(state, blueprint, time) do
      options =
        [:geode, :obsidian, :ore, :clay]
        |> Enum.filter(&can_build?(state, blueprint[&1]))
        |> Enum.filter(&worthwhile(state, blueprint, time, &1))
        |> Enum.take(2)

      built = options |> Enum.map(&build(state, &1, blueprint[&1]))
      if :geode in options or :obsidian in options, do: built, else: built ++ [state]
    end

    def worthwhile(_, _, time, :geode), do: time > 1

    def worthwhile(_, _, time, :obsidian) when time <= 2, do: false

    def worthwhile(%State{resources: res, robots: robots}, %{max_cost: worst}, time, :obsidian),
      do: res.obsidian + robots.obsidian * (time - 2) < (time - 1) * worst.obsidian

    def worthwhile(_, _, time, :ore) when time <= 2, do: false

    def worthwhile(%State{resources: res, robots: robots}, %{max_cost: worst}, time, :ore),
      do: res.ore + robots.ore * (time - 2) < (time - 1) * worst.ore

    def worthwhile(_, _, time, :clay) when time <= 3, do: false

    def worthwhile(%State{resources: res, robots: robots}, %{max_cost: worst}, time, :clay),
      do: res.clay + robots.clay * (time - 3) < (time - 2) * worst.clay

    def discard_unnecessary(%State{resources: res} = state, %{max_cost: worst}, time) do
      struct!(state,
        resources: %{
          ore: min(res.ore, worst.ore * (time - 1)),
          clay: min(res.clay, worst.clay * (time - 2)),
          obsidian: min(res.obsidian, worst.obsidian * (time - 1)),
          geode: res.geode
        }
      )
    end
  end

  @doc "Multiply blueprint IDs by max geode count over 24 minutes, sum results."
  def part1(input) do
    Enum.map(input, &parse_line/1)
    |> Enum.map(fn bp -> Task.async(fn -> {bp.id, best_score(%State{}, bp, 24)} end) end)
    |> Task.await_many(:infinity)
    |> Enum.map(fn {id, score} -> id * score end)
    |> Enum.sum()
  end

  @doc "Multiply the max geode count of the first 3 blueprints over 32 minutes."
  def part2(input) do
    Enum.map(Enum.take(input, 3), &parse_line/1)
    |> Enum.map(fn bp -> Task.async(fn -> best_score(%State{}, bp, 32) end) end)
    |> Task.await_many(:infinity)
    |> Enum.product()
  end

  defp best_score(state, bp, time) do
    cache = :ets.new(String.to_atom("cache_#{bp.id}"), [:set])
    stats = :ets.new(String.to_atom("stats_#{bp.id}"), [:set])
    :ets.update_counter(stats, :hits, 0, {:hits, 0})
    :ets.update_counter(stats, :misses, 0, {:misses, 0})
    best = best_score(state, bp, time, cache, stats)

    [hits, misses] =
      Enum.map([:hits, :misses], fn key -> Keyword.fetch!(:ets.lookup(stats, key), key) end)

    IO.puts(
      :stderr,
      "Blueprint #{bp.id} cache hits: #{hits} misses: #{misses} #{inspect(self())}"
    )

    :ets.delete(cache)
    :ets.delete(stats)
    best
  end

  defp best_score(state, _bp, 0, _cache, _stats), do: State.score(state)

  defp best_score(state, bp, time, cache, stats) do
    cache_key = {State.discard_unnecessary(state, bp, time), time}

    case :ets.lookup(cache, cache_key) do
      [{_, cached}] ->
        hits = :ets.update_counter(stats, :hits, 1, {:hits, 0})

        if rem(hits, 10_000_000) == 0,
          do: IO.puts(:stderr, "#{hits} cache hits time #{time} #{inspect(self())}")

        cached

      [] ->
        to_add = state.robots
        misses = :ets.update_counter(stats, :misses, 1, {:misses, 0})

        if rem(misses, 10_000_000) == 0,
          do: IO.puts(:stderr, "#{misses} cache misses time #{time} #{inspect(self())}")

        State.all_possible(state, bp, time)
        |> Enum.map(&State.add_resources(&1, to_add))
        |> Enum.map(fn x -> best_score(x, bp, time - 1, cache, stats) end)
        |> Enum.max()
        |> tap(fn best -> :ets.insert(cache, {cache_key, best}) end)
    end
  end

  @pattern ~r/Blueprint (\d+): Each ore robot costs (\d+) ore. Each clay robot costs (\d+) ore. Each obsidian robot costs (\d+) ore and (\d+) clay. Each geode robot costs (\d+) ore and (\d+) obsidian./
  defp parse_line(line) do
    [id, ore_cost, clay_cost, obsidian_ore, obsidian_clay, geode_ore, geode_obsidian] =
      Regex.run(@pattern, line)
      |> Enum.drop(1)
      |> Enum.map(&String.to_integer/1)

    prepare_blueprint(%{
      id: id,
      ore: %{ore: ore_cost},
      clay: %{ore: clay_cost},
      obsidian: %{ore: obsidian_ore, clay: obsidian_clay},
      geode: %{ore: geode_ore, obsidian: geode_obsidian}
    })
  end

  defp prepare_blueprint(bp) do
    Map.put(bp, :max_cost, %{
      ore: Enum.max([bp.ore.ore, bp.clay.ore, bp.obsidian.ore, bp.geode.ore]),
      clay: bp.obsidian.clay,
      obsidian: bp.geode.obsidian
    })
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day19, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day19.main()

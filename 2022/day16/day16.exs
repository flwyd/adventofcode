#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/16

defmodule Day16 do
  @moduledoc """
  Input describes a graph with 2-letter node names (valves) which produce a flow
  rate (some rates are 0).  Opening a valve takes one minute.  Moving from one
  valve to a connected valve takes one minute.  Total value is the sum of each
  open valve's rate times the number of minutes it was open.  Start at valve AA.
  """

  defmodule Explorer do
    defstruct cur: "", time: 0

    def move(explorer, to, time_cost) do
      struct!(explorer, cur: to, time: explorer.time - time_cost)
    end
  end

  defmodule State do
    # keep fields sorted so this can be used as a cache key
    defstruct explorers: [], can_open: []

    def normalize(state),
      do: struct!(state, explorers: Enum.sort_by(state.explorers, fn x -> x.time end, :desc))

    def open(state, valves) when is_list(valves) do
      struct!(state, can_open: Enum.sort(state.can_open -- valves))
    end

    def open(state, valve) when is_binary(valve), do: open(state, [valve])

    def move_explorer(state, exp, to, time_cost) do
      struct!(
        state,
        explorers: List.update_at(state.explorers, exp, &Explorer.move(&1, to, time_cost))
      )
    end

    def move(state, to, time_cost) do
      struct!(state, cur: to, time: state.time - time_cost)
    end
  end

  @doc "Find the maximum total flow from one explorer in 30 minutes."
  def part1(input), do: solve(input, [30])

  @doc "Find the maximum total flow from two explorers in 26 minutes each."
  def part2(input), do: solve(input, [26, 26])

  defp solve(input, times) do
    {flows, graph} = Enum.reduce(input, {%{}, %{}}, &parse_line/2)
    {compact, worth_opening} = compact_graph(flows, graph)

    initial = %State{
      explorers: Enum.map(times, &%Explorer{cur: "AA", time: &1}),
      can_open: worth_opening
    }

    cache = :ets.new(:cache, [:set])
    cache_stats = :ets.new(:cache_stats, [:set])
    value = find_best_score(flows, compact, initial, cache, cache_stats)

    [hits, misses] =
      Enum.map([:hits, :misses], fn key -> Keyword.fetch!(:ets.lookup(cache_stats, key), key) end)

    IO.puts(:stderr, "Cache hits: #{hits} misses: #{misses}")
    :ets.delete(cache)
    :ets.delete(cache_stats)
    value
  end

  defp find_best_score(_, _, %State{can_open: []}, _, _), do: 0

  defp find_best_score(_, _, %State{explorers: [%Explorer{time: 0}]}, _, _), do: 0

  defp find_best_score(flows, graph, %{explorers: [%{time: 0} | rest]} = state, cache, stats),
    do: find_best_score(flows, graph, struct!(state, explorers: rest), cache, stats)

  defp find_best_score(flows, graph, state, cache, stats) do
    case :ets.lookup(cache, state) do
      [{_, cached}] ->
        :ets.update_counter(stats, :hits, 1, {:hits, 0})
        cached

      [] ->
        :ets.update_counter(stats, :misses, 1, {:misses, 0})

        best =
          valid_move_groups(flows, graph, state, 0, 0)
          |> Enum.map(fn {move, value} ->
            value + find_best_score(flows, graph, State.normalize(move), cache, stats)
          end)
          |> Enum.max(fn -> 0 end)

        :ets.insert(cache, {state, best})
        best
    end
  end

  defp valid_move_groups(flows, graph, state, base_value, exp) do
    %Explorer{cur: cur, time: time} = Enum.at(state.explorers, exp)

    choices =
      case Enum.filter(graph[cur], fn {dest, cost} -> cost < time && dest in state.can_open end) do
        [] ->
          [{State.move_explorer(state, exp, cur, time), base_value}]

        list ->
          list
          |> Enum.sort_by(fn {x, cost} -> open_value(flows, x, time - cost) end, :desc)
          |> Enum.map(fn {dest, cost} ->
            {State.move_explorer(State.open(state, dest), exp, dest, cost + 1),
             open_value(flows, dest, time - cost) + base_value}
          end)
      end

    Enum.map(choices, fn {move, value} = choice ->
      if exp + 1 < length(state.explorers),
        do: valid_move_groups(flows, graph, move, value, exp + 1),
        else: choice
    end)
    |> List.flatten()
  end

  defp open_value(flows, cur, time), do: flows[cur] * (time - 1)

  defp compact_graph(flows, graph) do
    worth_opening = Map.reject(flows, fn {_, v} -> v == 0 end) |> Map.keys()

    compact =
      ["AA" | worth_opening]
      |> Enum.map(fn from ->
        {from,
         worth_opening
         |> Enum.reject(&(&1 == from))
         |> Enum.map(fn to -> {to, shortest_path(from, to, graph)} end)}
      end)
      |> Map.new()

    {compact, worth_opening}
  end

  defp shortest_path(from, to, graph, visited \\ MapSet.new())
  defp shortest_path(from, to, _, _) when from == to, do: 0

  defp shortest_path(from, to, graph, visited) do
    visited = MapSet.put(visited, from)

    options = MapSet.difference(graph[from], visited)

    if MapSet.size(options) == 0,
      do: 1_000_000,
      else:
        options
        |> (Enum.map(fn f -> shortest_path(f, to, graph, visited) end) |> Enum.min())
        |> then(&(&1 + 1))
  end

  defp parse_line(line, {flows, graph}) do
    [_, valve, rate, targets] =
      Regex.run(~r/Valve (..) has flow rate=(\d+); tunnels? leads? to valves? (.*)/, line)

    target_valves = String.split(targets, ", ")

    {Map.put(flows, valve, String.to_integer(rate)),
     Map.put(graph, valve, MapSet.new(target_valves))}
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day16, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day16.main()

#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/16

defmodule Day16 do
  def part1(input) do
    {flows, graph} = Enum.reduce(input, {%{}, %{}}, &parse_line/2)
    worth_opening = Map.reject(flows, fn {k, v} -> v == 0 end) |> Map.keys()
    IO.inspect(worth_opening)

    compact =
      ["AA" | worth_opening]
      |> Enum.map(fn from ->
        {from,
         worth_opening
         |> Enum.reject(&(&1 == from))
         |> Enum.map(fn to -> {to, shortest_path(from, to, graph)} end)}
      end)
      |> Map.new()

    # perms = permutations(Map.keys(compact) -- ["AA"]) |> Enum.map(fn perms -> ["AA" | perms] end)
    # compact = Map.put(compact, "AA", Enum.map(Map.keys(graph), &({&1, 1})))
    IO.inspect(compact)
    {:ok, cache_agent} = Agent.start_link(fn -> %{} end)

    # {value, best, cache} =
    {value, best} = find_best("AA", flows, compact, ["AA" | worth_opening], 30, cache_agent)

    # IO.inspect(Enum.count(perms))
    # IO.inspect(List.first(perms))
    # {best, value} =
    #   Enum.map(perms, fn perm -> {perm, total_value(perm, flows, compact, 30, 0)} end)
    #   |> Enum.max_by(&elem(&1, 1))

    IO.puts("best")
    IO.inspect(best)
    # IO.inspect(cache[{"DD", 29}])
    total_value(best, flows, compact, 30, 0, true)
    # Enum.reduce(best, {30, 0}, fn valve, {time, value} ->
    # IO.puts("#{valve}, #{time}, #{value}")
    # end
    value

    # open = MapSet.new()
    # time = 30
    # dfs("AA", flows, compact, open, MapSet.new(worth_opening), time, 0)
  end

  def part2(input) do
    :todo
  end

  defp permutations([]), do: [[]]
  defp permutations(list), do: for(h <- list, t <- permutations(list -- [h]), do: [h | t])

  defp total_value(list, flows, graph, time, value, verbose \\ false)
  defp total_value([], _, _, _, value, _), do: value
  defp total_value(_, _, _, time, value, _) when time <= 0, do: value

  defp total_value([cur], flows, graph, time, value, verbose) do
    if verbose,
      do: IO.puts("Final item: #{cur} time #{time} value #{value} + #{flows[cur] * (time - 1)}")

    (time - 1) * flows[cur] + value
  end

  defp total_value([cur, next | rest], flows, graph, time, value, verbose) do
    {spent, val} = if flows[cur] > 0, do: {1, (time - 1) * flows[cur] + value}, else: {0, value}
    {^next, cost} = Enum.find(graph[cur], fn {x, _} -> x == next end)

    if verbose,
      do: IO.puts("Item: #{cur} time #{time} value #{value} new #{val} cost #{cost} next #{next}")

    total_value([next | rest], flows, graph, time - cost - spent, val, verbose)
  end

  # defp find_best(cur, flows, graph, [], time, pressure, cache), do: {pressure, [], cache}
  defp find_best(cur, flows, graph, [], time, cache_agent), do: {0, []}

  # defp find_best(cur, flows, graph, can_open, time, pressure) when time <= 0,
  # do: {pressure, [], cache}
  defp find_best(cur, flows, graph, can_open, time, cache_agent) when time <= 0, do: {0, []}

  # defp find_best(cur, flows, graph, can_open, time, pressure, cache) do
  defp find_best(cur, flows, graph, can_open, time, cache_agent) do
    # case Map.get(cache, {cur, time}) do
    case Agent.get(cache_agent, fn cache -> Map.get(cache, {cur, time, MapSet.new(can_open)}) end) do
      nil ->
        with do
          # if cur in open, do: raise("Cur #{cur} already in open #{inspect(open)}")
          # open = MapSet.put(open, cur)
          to_open_or_not =
            if cur in can_open,
              do: [{1, (time - 1) * flows[cur], can_open -- [cur]}, {0, 0, can_open}],
              else: [{0, 0, can_open}]

          {best, path} =
            for {spent, val, new_open} <- to_open_or_not do
              # IO.puts("#{cur} spent #{spent}, val #{val}, open #{new_open} time #{time}")
              [{val, [cur]}] ++
              (Enum.reject(graph[cur], fn {x, cost} -> cost >= time end)
              |> Enum.map(fn {option, cost} ->
                {found, path} =
                  find_best(option, flows, graph, new_open, time - spent - cost, cache_agent)

                {found + val, [cur | path]}
              end))
            end
            |> List.flatten()
            |> Enum.max()

          Agent.update(cache_agent, fn cache -> Map.put(cache, {cur, time, MapSet.new(can_open)}, {best, path}) end)
          {best, path}

          # case graph[cur] |> Enum.reject(fn {x, cost} -> cost >= time end) do
          #   [] ->
          #     with do
          #       {spent, val} =
          #         if cur in can_open,
          #           do: {1, (time - 1) * flows[cur] + pressure},
          #           else: {0, pressure}
          #
          #       # cache = Map.put(cache, {cur, time}, {val, [cur]})
          #       # {val, [cur], cache}
          #       Agent.update(cache_agent, fn cache ->
          #         Map.put(cache, {cur, time}, {val, [cur]})
          #       end)
          #
          #       {val, [cur]}
          #     end
          #
          #   options ->
          #     with do
          #       to_open_or_not =
          #         if cur in can_open,
          #           do: [{1, (time - 1) * flows[cur] + pressure}, {0, pressure}],
          #           else: [{0, pressure}]
          #
          #       can_open = can_open -- [cur]
          #
          #       {best, path} =
          #         for {spent, val} <- to_open_or_not, {opt, cost} <- options do
          #           find_best(opt, flows, graph, can_open, time - cost - spent, val, cache_agent)
          #         end
          #         |> Enum.max()
          #
          #       # {best, path, cache} =
          #       #   Enum.reduce(options, {pressure, [], cache}, fn {x, cost},
          #       #                                                  {best, best_path, cache} ->
          #       #     {v, path, cache} =
          #       #       Enum.map([{spent, val}, {0, pressure}], fn {sp, pres} ->
          #       #         find_best(x, flows, graph, can_open, time - cost - sp, pres, cache)
          #       #       end)
          #       #       |> Enum.reduce(fn {vx, px, cachex}, {vacc, pacc, cacheacc} ->
          #       #         Tuple.append(max({vx, px}, {vacc, pacc}), cachex)
          #       #       end)
          #       #
          #       #     if v > best, do: {v, path, cache}, else: {best, best_path, cache}
          #       #     # {max(best, v), cache}
          #       #   end)
          #
          #       IO.puts(
          #         "Best from #{cur} at #{time} is #{best} #{[cur | path]} can open #{can_open}"
          #       )
          #
          #       Agent.update(cache_agent, fn cache ->
          #         Map.put(cache, {cur, time}, {best, [cur | path]})
          #       end)
          #
          #       {best, [cur | path]}
          #       # {best, [cur | path], Map.put(cache, {cur, time}, {best, [cur | path]})}
          #     end
          # end
        end

      {cached, path} ->
        # {cached, path, cache}
        {cached, path}
    end
  end

  defp dfs(cur, flows, graph, open, worth_opening, time, pressure) when time < 0, do: -1
  defp dfs(cur, flows, graph, open, worth_opening, 0, pressure), do: pressure

  defp dfs(cur, flows, graph, open, worth_opening, time, pressure) do
    if MapSet.equal?(worth_opening, open) do
      # IO.puts("Not worth opening more at time #{time}, returning #{pressure}")
      pressure
    else
      # IO.puts("Investigating #{cur} at time #{time} with pressure #{pressure}, #{inspect(open)} open")

      # IO.puts("Opening #{cur} at time #{time} with #{MapSet.size(open)} others")
      ([
         if flows[cur] > 0 && !MapSet.member?(open, cur) do
           dfs(
             cur,
             flows,
             graph,
             MapSet.put(open, cur),
             worth_opening,
             time - 1,
             flows[cur] * (time - 1) + pressure
           )
         else
           pressure
         end
       ] ++
         Enum.map(graph[cur], fn {x, cost} ->
           dfs(x, flows, graph, open, worth_opening, time - cost, pressure)
         end))
      |> Enum.max()
    end
  end

  defp shortest_path(from, to, graph, visited \\ MapSet.new())
  defp shortest_path(from, to, graph, visited) when from == to, do: 0

  defp shortest_path(from, to, graph, visited) do
    # IO.puts("CHecking shortest path #{inspect(from)} to #{inspect(to)}")
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

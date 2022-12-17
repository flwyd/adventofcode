#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/16

defmodule Day16 do
  defmodule Explorer do
    defstruct cur: "", time: 0

    def move(explorer, to, time_cost) do
      struct!(explorer, cur: to, time: explorer.time - time_cost)
    end
  end

  defmodule State do
    # keep can_open sorted so this can be used as a cache key
    # defstruct first: %Explorer{}, second: %Explorer{}, can_open: []
    defstruct explorers: [], can_open: []

    def normalize(state),
      do: struct!(state, explorers: Enum.sort_by(state.explorers, fn x -> x.time end, :desc))

    def open(state, valves) when is_list(valves) do
      struct!(state, can_open: Enum.sort(state.can_open -- valves))
    end

    def move_explorer(state, exp, to, time_cost) do
      # struct!(state, [exp, Explorer.move(state[exp], to, time_cost)])
      struct!(
        state,
        # explorers: Map.update!(state.explorers, exp, &Explorer.move(&1, to, time_cost))
        explorers: List.update_at(state.explorers, exp, &Explorer.move(&1, to, time_cost))
      )
    end

    def move_first(state, to, time_cost) do
      # struct!(state, first: Explorer.move(state.first, to, time_cost))
      # move_explorer(state, :first, to, time_cost)
      move_explorer(state, 0, to, time_cost)
    end

    def move_second(state, to, time_cost) do
      # struct!(state, second: Explorer.move(state.second, to, time_cost))
      # move_explorer(state, :second, to, time_cost)
      move_explorer(state, 1, to, time_cost)
    end

    def move(state, to, time_cost) do
      struct!(state, cur: to, time: state.time - time_cost)
    end
  end

  def part1(input) do
    {flows, graph} = Enum.reduce(input, {%{}, %{}}, &parse_line/2)
    worth_opening = Map.reject(flows, fn {_k, v} -> v == 0 end) |> Map.keys()
    # IO.inspect(worth_opening)

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
    # IO.inspect(compact)
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
    Agent.stop(cache_agent)
    value

    # open = MapSet.new()
    # time = 30
    # dfs("AA", flows, compact, open, MapSet.new(worth_opening), time, 0)
  end

  def part2(input) do
    {flows, graph} = Enum.reduce(input, {%{}, %{}}, &parse_line/2)
    worth_opening = Map.reject(flows, fn {k, v} -> v == 0 end) |> Map.keys()

    compact =
      ["AA" | worth_opening]
      |> Enum.map(fn from ->
        {from,
         worth_opening
         |> Enum.reject(&(&1 == from))
         |> Enum.map(fn to -> {to, shortest_path(from, to, graph)} end)}
      end)
      |> Map.new()

    # initial = %State{first: %Explorer{cur: "AA", time: 26}, second: %Explorer{cur: "AA", time: 26}, can_open: worth_opening}
    initial = %State{
      # explorers: %{first: %Explorer{cur: "AA", time: 26}, second: %Explorer{cur: "AA", time: 26}},
      explorers: [%Explorer{cur: "AA", time: 26}, %Explorer{cur: "AA", time: 26}],
      can_open: worth_opening
    }

    # {:ok, cache_agent} = Agent.start_link(fn -> %{} end)
    # TODO better naming
    table_name = "part2_#{Enum.count(input)}"
    cache_table = :ets.new(String.to_atom(table_name), [:set])
    best_cache = :ets.new(String.to_atom("best_#{table_name}"), [:set])
    # {best, path} = find_best_2(flows, compact, initial, cache_agent)
    {best, path} = find_best_2(flows, compact, initial, cache_table, best_cache)
    cache_size = :ets.info(cache_table, :size)
    IO.puts("Final cache size #{cache_size}")
    IO.puts("Best path gets #{best}")
    IO.inspect(path)
    # Agent.stop(cache_agent)
    :ets.delete(cache_table)
    :ets.delete(best_cache)
    best
  end

  defp find_best_2(_, _, %State{can_open: []}, _, _), do: {0, []}

  defp find_best_2(
         _,
         _,
         %State{explorers: [%Explorer{time: time_a}, %Explorer{time: time_b}]},
         _,
         _
       )
       when time_a <= 0 and time_b <= 0,
       do: {0, []}

  # defp find_best_2(_, _, %State{time: time}, _) when time <= 0, do: {0, []}
  # defp find_best_2(
  #        _,
  #        _,
  #        %State{explorers: %{first: %Explorer{time: time_a}, second: %Explorer{time: time_b}}},
  #        _,
  #        _
  #      )
  #      when time_a <= 0 and time_b <= 0,
  #      do: {0, []}

  # defp find_best_2(flows, graph, state, cache_agent) do
  # case Agent.get(cache_agent, fn cache -> Map.get(cache, state) end, :infinity) do
  defp find_best_2(flows, graph, state, cache_table, best_cache) do
    case :ets.lookup(cache_table, state) do
      [] ->
        with do
          best_key = {Enum.map(state.explorers, & &1.time) |> Enum.sort(:desc), state.can_open}
          # {Enum.sort([state.explorers[:first].time, state.explorers[:second].time]),

          best_so_far =
            case :ets.lookup(best_cache, best_key) do
              [] -> 0
              [{^best_key, so_far}] -> so_far
            end

          # for {move_a, value_a} <- valid_moves(flows, graph, :first, state),
          #     {move_b, value_b} <- valid_moves(flows, graph, :second, move_a),
          # {best, path} = find_best_2(flows, graph, move_b, cache_agent)
          {best, path} =
            for {move_a, value_a} <- valid_moves(flows, graph, 0, state),
                {move_b, value_b} <- valid_moves(flows, graph, 1, move_a),
                value_a + value_b + best_possible_value(flows, graph, state) > best_so_far do
              {best, path} =
                find_best_2(flows, graph, State.normalize(move_b), cache_table, best_cache)

              {best + value_a + value_b, [Enum.map(state.explorers, & &1.cur) | path]}
              #  [[state.explorers[:first].cur, state.explorers[:second].cur] | path]}
            end
            |> Enum.max(fn -> {0, []} end)

          # Agent.update(cache_agent, fn cache -> Map.put(cache, state, {best, path}) end, :infinity)
          cache_size = :ets.info(cache_table, :size)

          if rem(cache_size, 1_000_000) == 0,
            do: IO.puts("Cache size #{cache_size} state #{inspect(state)}")

          :ets.insert(cache_table, {state, {best, path}})
          # if best > best_so_far, do: :ets.insert(best_cache, {best_key, best})
          for x <- Enum.at(state.explorers, 0).time..26,
              y <- Enum.at(state.explorers, 1).time..26 do
            key = {Enum.sort([x, y], :desc), state.can_open}

            case :ets.lookup(best_cache, key) do
              [] -> :ets.insert(best_cache, {key, best})
              [{^key, so_far}] when best > so_far -> :ets.insert(best_cache, {key, best})
              _ -> false
            end
          end

          {best, path}
        end

      [{_, cached}] ->
        cached
    end
  end

  # defp best_possible_value(flows, can_open, times) do
  defp best_possible_value(flows, graph, %State{can_open: can_open} = state) do
    # Enum.map(state.explorers, & &1.time) |> Enum.sort(:desc)
    [exp1, exp2] = state.explorers

    can_open
    |> Enum.sort_by(&flows[&1], :desc)
    |> Enum.chunk_every(2, 2, ["AA"])
    |> Enum.with_index(1)
    |> Enum.map(fn {[a, b], i} ->
      flows[a] * (exp1.time - elem(Enum.find(graph[exp1.cur], {exp1.cur, 1}, &(&1 == a)), 1)) +
        flows[b] * (exp2.time - elem(Enum.find(graph[exp2.cur], {exp2.cur, 1}, &(&1 == b)), 1))
    end)
    |> Enum.sum()
  end

  defp valid_moves(flows, graph, exp, state) do
    %Explorer{cur: cur, time: time} = Enum.at(state.explorers, exp)
    # %Explorer{cur: cur, time: time} = state.explorers[exp]

    open =
      if cur in state.can_open,
        do: [
          {State.open(State.move_explorer(state, exp, cur, 1), [cur]),
           open_value(flows, cur, time)}
        ],
        else: []

    open ++
      case Enum.filter(graph[cur], fn {dest, cost} -> cost < time && dest in state.can_open end) do
        [] ->
          if Enum.empty?(open), do: [{State.move_explorer(state, exp, cur, time), 0}], else: []

        list ->
          list
          |> Enum.sort_by(fn {x, cost} -> flows[x] * (time - cost) end, :desc)
          |> Enum.map(fn {dest, cost} -> {State.move_explorer(state, exp, dest, cost), 0} end)
      end
  end

  defp open_value(flows, cur, time), do: flows[cur] * (time - 1)
  # defp find_best_2(flows, graph, %State{cur: [cur_a, cur_b]} = state, cache_agent) do
  #   case Agent.get(cache_agent, fn cache -> Map.get(cache, state) end) do
  #     nil ->
  #       with do
  #         open_opts =
  #           cond do
  #             cur_a == cur_b && cur_a in state.can_open ->
  #               [{true, false, State.open(state, [cur_a])}, {false, false, state}]
  #
  #             cur_a == cur_b ->
  #               [{false, false, state}]
  #
  #             cur_a in state.can_open && cur_b in state.can_open ->
  #               [
  #                 {true, true, State.open(state, [cur_a, cur_b])},
  #                 {true, false, State.open(state, [cur_a])},
  #                 {false, true, State.open(state, [cur_b])},
  #                 {false, false, state}
  #               ]
  #
  #             cur_a in state.can_open ->
  #               [{true, false, State.open(state, [cur_a])}, {false, false, state}]
  #
  #             cur_b in state.can_open ->
  #               [{false, true, State.open(state, [cur_b])}, {false, false, state}]
  #
  #             true ->
  #               [{false, false, state}]
  #           end
  #
  #         {best, path} =
  #           for {open_a, open_b, new_state} <- open_opts do
  #             value =
  #               if(open_a, do: flows[cur_a] * (state.time - 1), else: 0) +
  #                 if open_b, do: flows[cur_b] * (state.time - 1), else: 0
  #
  #             next_a = if open_a, do: [cur_a], else: graph[cur_a]
  #             next_b = if open_b, do: [cur_b], else: graph[cur_b]
  #
  #             for a <- next_a, b <- next_b do
  #               move = [a, b]
  #               {best, path} = find_best_2(flows, graph, State.move(new_state, move, 1), cache_agent)
  #               {best + value, [state.cur | path]}
  #             end
  #           end
  #           |> List.flatten()
  #           |> Enum.max()
  #
  #         Agent.update(cache_agent, fn cache -> Map.put(cache, state, {best, path}) end)
  #
  #         {best, path}
  #       end
  #
  #     cached ->
  #       cached
  #   end
  # end

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

          Agent.update(cache_agent, fn cache ->
            Map.put(cache, {cur, time, MapSet.new(can_open)}, {best, path})
          end)

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

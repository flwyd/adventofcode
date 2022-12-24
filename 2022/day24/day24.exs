#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/24

defmodule Day24 do
  @moduledoc """
  Input is a grid of `.` open spaces and obstacles moving in cardinal directions
  indicated by `<>^v`.  Obstacles wrap around the grid, remaining in their row
  or column.  The grid has `#` walls around the edge but with a `.` gap in the
  first and last line.  Entrance is at the first gap, exit is at the last gap.
  You can move in the cardinal directions or stay put, and can't occupy the same
  space as an obstacle, but obstacles can stack on each other.
  """

  defmodule PQ do
    def new(priority, value), do: add_at(%{}, priority, value)

    def add_at(pq, priority, value), do: Map.update(pq, priority, [value], &(&1 ++ [value]))

    def shift_next(pq) do
      if Enum.empty?(pq), do: raise("Empty PQ")

      case Enum.min(pq) do
        {priority, [value]} -> {priority, value, Map.delete(pq, priority)}
        {priority, [value | rest]} -> {priority, value, Map.put(pq, priority, rest)}
      end
    end
  end

  @doc "Move from entrance to exit in the fewest turns."
  def part1(input) do
    {%{entrance: ent, exit: exit, height: height, width: width} = dims, grid} = parse_input(input)
    dist = distance(ent, exit)
    start = {ent, 0}
    if height * width < 50, do: print_grid(grid, ent, dims)
    bfs(exit, dims, %{0 => grid}, PQ.new(dist, start), MapSet.new([start]))
  end

  @doc "Move from entrance to exit, back to entrance, and back to exit."
  def part2(input) do
    {%{entrance: ent, exit: exit} = dims, grid} = parse_input(input)
    dist = distance(ent, exit)

    Enum.reduce([{ent, exit}, {exit, ent}, {ent, exit}], 0, fn {src, dest}, total_turns ->
      {grid, _} = turn_grid(total_turns, %{0 => grid}, dims)
      start = {src, 0}
      total_turns + bfs(dest, dims, %{0 => grid}, PQ.new(dist, start), MapSet.new([start]))
    end)
  end

  defp distance({row, col}, {dest_row, dest_col}), do: abs(dest_row - row) + abs(dest_col - col)

  defp moves({row, col} = cur, dest, height, width, blockers) do
    Enum.map([{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {0, 0}], fn {dr, dc} -> {row + dr, col + dc} end)
    |> Enum.filter(fn {r, c} = p ->
      (r in 1..(height - 1) and c in 1..(width - 1)) or p in [dest, cur]
    end)
    |> Enum.filter(fn p -> Enum.empty?(Map.get(blockers, p, [])) end)
  end

  defp bfs(dest, dims, grids, pq, visited) do
    {_priority, {pos, turn}, pq} = PQ.shift_next(pq)

    if dest === pos do
      turn
    else
      {next_grid, grids} = turn_grid(turn + 1, grids, dims)

      opts =
        moves(pos, dest, dims.height, dims.width, next_grid)
        |> Enum.map(&{&1, turn + 1})
        |> Enum.reject(&(&1 in visited))

      visited = MapSet.union(visited, MapSet.new(opts))

      pq =
        Enum.reduce(opts, pq, fn {move, turn}, pq ->
          PQ.add_at(pq, turn + distance(move, dest), {move, turn})
        end)

      bfs(dest, dims, grids, pq, visited)
    end
  end

  defp turn_grid(turn, grids, dims) do
    case Map.get(grids, turn) do
      nil ->
        {prev, grids} = turn_grid(turn - 1, grids, dims)
        next = move_grid(prev, dims.height, dims.width)
        {next, Map.put(grids, turn, next)}

      cached ->
        {cached, grids}
    end
  end

  defp move_grid(grid, height, width) do
    Enum.reduce(grid, %{}, fn {{row, col}, movers}, g ->
      Enum.reduce(movers, g, fn {dr, dc} = dir, g ->
        r =
          case row + dr do
            0 -> height - 1
            ^height -> 1
            r -> r
          end

        c =
          case col + dc do
            0 -> width - 1
            ^width -> 1
            c -> c
          end

        Map.update(g, {r, c}, [dir], &[dir | &1])
      end)
    end)
  end

  defp parse_input([first | rest]) do
    start = String.to_charlist(first) |> Enum.find_index(&(&1 === ?.))
    parse_input(rest, 1, %{entrance: {0, start}, width: String.length(first) - 1}, %{})
  end

  defp parse_input([last], row, dims, grid) do
    exit = String.to_charlist(last) |> Enum.find_index(&(&1 === ?.))
    {Map.merge(dims, %{exit: {row, exit}, height: row}), grid}
  end

  defp parse_input([next | rest], row, dims, grid) do
    grid =
      next
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.reject(fn {c, _} -> c === ?# end)
      |> Enum.map(fn
        {?., col} -> {{row, col}, []}
        {?<, col} -> {{row, col}, [{0, -1}]}
        {?>, col} -> {{row, col}, [{0, 1}]}
        {?^, col} -> {{row, col}, [{-1, 0}]}
        {?v, col} -> {{row, col}, [{1, 0}]}
      end)
      |> Enum.into(grid)

    parse_input(rest, row + 1, dims, grid)
  end

  defp print_grid(grid, pos, %{width: width, height: height, entrance: ent, exit: exit}) do
    for row <- 0..height do
      Enum.map(0..width, fn col ->
        case {row, col} do
          ^pos -> ?E
          ^ent -> ?.
          ^exit -> ?.
          {0, _} -> ?#
          {_, 0} -> ?#
          {^height, _} -> ?#
          {_, ^width} -> ?#
          other -> grid_char(other, grid)
        end
      end)
      |> then(&IO.puts(:stderr, &1))
    end
  end

  defp grid_char(pos, grid) do
    case grid[pos] do
      nil -> ?.
      [] -> ?.
      [{0, -1}] -> ?<
      [{0, 1}] -> ?>
      [{-1, 0}] -> ?^
      [{1, 0}] -> ?v
      [_ | _] = list -> Enum.count(list) + ?0
    end
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day24, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day24.main()

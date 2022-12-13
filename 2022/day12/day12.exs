#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/12

defmodule Day12 do
  @moduledoc """
  Input is a 2D grid of lower case letters indicating heights, with `S` and `E`
  marking the start and end positions.  Movement in the cardinal direction is
  allowed if height does not increase by more than one (unlimited decrease is
  allowed).
  """

  @doc "Count the steps in the shortest path from start to end."
  def part1(input) do
    {grid, start, stop} = parse(input)
    bfs(:queue.from_list([{start, 0}]), grid, stop, MapSet.new([start]))
  end

  @doc "Find the shorted path to end starting at any `a` position."
  def part2(input) do
    {grid, _start, stop} = parse(input)
    starts = Map.filter(grid, fn {_, height} -> height == ?a end) |> Map.keys()
    bfs(:queue.from_list(Enum.map(starts, &{&1, 0})), grid, stop, MapSet.new(starts))
  end

  defp parse(input) do
    input
    |> Enum.with_index(1)
    |> Enum.reduce({%{}, 0, 0}, fn {line, row}, accout ->
      to_charlist(line)
      |> Enum.with_index(1)
      |> Enum.reduce(accout, fn {char, col}, {grid, start, stop} ->
        coord = {row, col}

        case char do
          ?S -> {Map.put(grid, coord, ?a), coord, stop}
          ?E -> {Map.put(grid, coord, ?z), start, coord}
          _ -> {Map.put(grid, coord, char), start, stop}
        end
      end)
    end)
  end

  defp bfs(queue, grid, target, visited) do
    case :queue.out(queue) do
      {:empty, _} ->
        :not_found

      {{:value, {^target, moves}}, _} ->
        moves

      {{:value, {coord, moves}}, q} ->
        with do
          next =
            valid_moves(coord, grid)
            |> Enum.filter(&(!MapSet.member?(visited, &1)))
            |> Enum.map(&{&1, moves + 1})

          q = Enum.reduce(next, q, &:queue.in(&1, &2))
          bfs(q, grid, target, MapSet.union(visited, MapSet.new(next |> Enum.map(&elem(&1, 0)))))
        end
    end
  end

  defp valid_moves({row, col}, grid) do
    cur_height = grid[{row, col}]

    [{-1, 0}, {1, 0}, {0, -1}, {0, 1}]
    |> Enum.map(fn {x, y} -> {row + x, col + y} end)
    |> Enum.filter(&Map.has_key?(grid, &1))
    |> Enum.filter(fn coord -> grid[coord] - cur_height <= 1 end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day12, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day12.main()

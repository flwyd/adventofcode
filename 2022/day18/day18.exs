#! /usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/18

defmodule Day18 do
  @moduledoc "Input is comma-separated 3D coordinates representing cubes."

  @doc "Count the number of cube faces not adjacent to another cube."
  def part1(input) do
    pts = Enum.map(input, &parse_line/1) |> MapSet.new()

    Enum.map(pts, fn p -> neighbors(p) |> Enum.reject(fn x -> MapSet.member?(pts, x) end) end)
    |> List.flatten()
    |> Enum.count()
  end

  @doc "Like part 1, but ignore internal holes."
  def part2(input) do
    pts = Enum.map(input, &parse_line/1) |> MapSet.new()
    {min, max} = pts |> Enum.map(&Tuple.to_list/1) |> List.flatten() |> Enum.min_max()
    mm = (min - 1)..(max + 1)
    in_range = fn {x, y, z} -> x in mm && y in mm && z in mm end
    min_point = {min - 1, min - 1, min - 1}

    Enum.reduce_while(Stream.cycle([nil]), {0, [min_point], MapSet.new([min_point])}, fn
      nil, {count, [], _} ->
        {:halt, count}

      nil, {count, [head | queue], visited} ->
        interesting = neighbors(head) |> Enum.filter(in_range)

        {:cont,
         Enum.reduce(interesting, {count, queue, visited}, fn n, {count, queue, visited} ->
           case {MapSet.member?(pts, n), MapSet.member?(visited, n), in_range.(n)} do
             {true, false, true} -> {count + 1, queue, visited}
             {false, false, true} -> {count, [n | queue], MapSet.put(visited, n)}
             {false, true, true} -> {count, queue, visited}
             {false, false, false} -> {count, queue, visited}
           end
         end)}
    end)
  end

  @dirs [{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}]
  defp neighbors({x, y, z}), do: Enum.map(@dirs, fn {dx, dy, dz} -> {x + dx, y + dy, z + dz} end)

  defp parse_line(line),
    do: String.split(line, ",") |> Enum.map(&String.to_integer/1) |> List.to_tuple()

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day18, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day18.main()

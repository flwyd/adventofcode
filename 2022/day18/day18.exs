#! /usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/18

defmodule Day18 do
  def part1(input) do
    pts = Enum.map(input, &parseline/1) |> MapSet.new()

    for p <- pts do
      neighbors(p) |> Enum.reject(fn x -> MapSet.member?(pts,  x) end)
    end
    |> List.flatten() |> Enum.count()
  end

  def part2(input) do
    :todo
  end

  defp neighbors({x, y, z} = point) do
    # dirs = for x <- -1..1, y <- -1..1, z <- -1..1, x != 0 || y != 0 || z != 0, do: {x, y, z}
    dirs = [{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}]
    Enum.map(dirs, fn {dx, dy, dz} -> {x + dx, y + dy, z + dz} end)
  end

  defp parseline(line),
    do: String.split(line, ",") |> Enum.map(&String.to_integer/1) |> List.to_tuple()

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day18, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day18.main()

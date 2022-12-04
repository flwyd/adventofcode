#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/4

defmodule Day4 do
  @moduledoc "Input is pairs of integer ranges like 36-49,25-64."
  import Enum, only: [map: 2, filter: 2, count: 1, sort_by: 2]
  import String, only: [split: 2, to_integer: 1]

  @doc "Count the number of pairs where one range is completely included in the other."
  def part1(input) do
    input |> map(&parse/1) |> filter(&range_subset?/1) |> count()
  end

  @doc "Count the number of pairs where one range overlaps the other at all."
  def part2(input) do
    input |> map(&parse/1) |> filter(fn {a, b} -> !Range.disjoint?(a, b) end) |> count()
  end

  defp parse(line), do: line |> split(",") |> map(&to_range/1) |> List.to_tuple()

  defp to_range(str) do
    str |> split("-") |> map(&to_integer/1) |> then(fn [lo, hi] -> lo..hi end)
  end

  defp range_subset?({first, second}) do
    # sort by Range start, ties go to the longer range
    [a, b] = sort_by([first, second], fn lo .. hi -> {lo, -hi} end)
    a.last >= b.last
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day4, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day4.main()

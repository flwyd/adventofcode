#! /usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/25

defmodule Day25 do
  @moduledoc """
  Input is base 5 numbers with digits valued -2 to 2.  -2 is `=` and -1 is `-`.
  Sum them, then print that in the same scheme.
  """

  def part1(input) do
    sum =
      Enum.map(input, &String.to_charlist/1)
      |> Enum.map(fn chars ->
        Enum.with_index(Enum.reverse(chars), 0)
        |> Enum.reduce(0, fn {c, i}, num ->
          num +
            trunc(:math.pow(5, i)) *
              case c do
                ?2 -> 2
                ?1 -> 1
                ?0 -> 0
                ?- -> -1
                ?= -> -2
              end
        end)
      end)
      |> Enum.sum()

    convert(sum)
  end

  defp convert(0), do: [?0]
  defp convert(1), do: [?1]
  defp convert(2), do: [?2]

  defp convert(sum) do
    {carry, digit} =
      case rem(sum, 5) do
        4 -> {1, ?-}
        3 -> {1, ?=}
        2 -> {0, ?2}
        1 -> {0, ?1}
        0 -> {0, ?0}
      end

    convert(div(sum, 5) + carry) ++ [digit]
  end

  def part2(input) do
    "Merry Christmas"
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day25, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day25.main()

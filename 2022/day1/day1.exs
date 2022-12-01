#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/1

defmodule Day1 do
  @moduledoc """
  Input is one integer per line, grouped with blank line separators.
  Each line represents the number of calories is in a snack carried by an elf.
  The sum of calories in a chunk are relevant to the puzzle.
  """

  @doc "Returns the maximum number of calories carried by any elf."
  def part1(input) do
    Enum.max(sum_chunks(input))
  end

  @doc "Returns the total calories carried by the three best-stocked elves."
  def part2(input) do
    Enum.sort(sum_chunks(input), :desc) |> Enum.take(3) |> Enum.sum()
  end

  defp sum_chunks(input), do: Enum.chunk_while(input, [], &chunk_lines/2, &(chunk_lines("", &1)))

  defp chunk_lines("", []), do: {:cont, []} # ignore excess blanks, just in case
  defp chunk_lines("", acc), do: {:cont, Enum.sum(acc), []}
  defp chunk_lines(number, acc), do: {:cont, [String.to_integer(number) | acc]}

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day1, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day1.main()

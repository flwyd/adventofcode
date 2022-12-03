#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/3

defmodule Day3 do
  @moduledoc """
  Input is lines of upper- and lower-case letters.
  Lower-case letters score alphabetic position, upper-case score position + 26.
  """

  @doc "Sum scores of the one matching letter in the first and second half of each line."
  def part1(input) do
    for line <- input do
      line |> bisect |> common |> only_element |> score
    end
    |> Enum.sum()
  end

  @doc "Each group of three lines has one matching letter, sum the letter score of each group."
  def part2(input) do
    for group <- Enum.chunk_every(input, 3) do
      group |> Enum.map(&String.to_charlist/1) |> common |> only_element |> score
    end
    |> Enum.sum()
  end

  defp bisect(line) do
    String.split_at(line, div(String.length(line), 2))
    |> Tuple.to_list()
    |> Enum.map(&String.to_charlist/1)
  end

  defp common([solo]), do: MapSet.new(solo)
  defp common([head | tail]), do: MapSet.new(head) |> MapSet.intersection(common(tail))

  defp only_element(set) do
    case MapSet.size(set) do
      1 -> set |> MapSet.to_list() |> List.first()
    end
  end

  defp score(char) do
    cond do
      char in ?a..?z -> char - ?a + 1
      char in ?A..?Z -> char - ?A + 27
    end
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day3, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day3.main()

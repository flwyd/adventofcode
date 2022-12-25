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
  Example: 9 is `2-` (2 5s minus 1), 51 is `201` (2 25s, no 5s, plus 1),
  75 is `1=00` (1 125 minus 2 25s, no 5s or 1s)..
  """

  @digit_int %{?2 => 2, ?1 => 1, ?0 => 0, ?- => -1, ?= => -2}
  @int_carry_digit %{4 => {1, ?-}, 3 => {1, ?=}, 2 => {0, ?2}, 1 => {0, ?1}, 0 => {0, ?0}}

  @doc "Sum all numbers in the input, return the result in the -2 to 2 format."
  def part1(input) do
    Enum.map(input, &String.to_charlist/1)
    |> Enum.map(fn chars ->
      Enum.with_index(Enum.reverse(chars), 0)
      |> Enum.reduce(0, fn {c, i}, num -> num + trunc(:math.pow(5, i)) * @digit_int[c] end)
    end)
    |> Enum.sum()
    |> convert()
  end

  def convert(x) when x >= 0 and x <= 2, do: [elem(@int_carry_digit[x], 1)]

  def convert(sum) do
    {carry, digit} = @int_carry_digit[rem(sum, 5)]
    convert(div(sum, 5) + carry) ++ [digit]
  end

  @doc "All problems are complete, have a pleasant night."
  def part2(_input), do: "Merry Christmas"

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day25, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day25.main()

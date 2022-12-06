#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/6

defmodule Day6 do
  @moduledoc """
  Input is a single line of gibberish characters.  Markers are found when a
  fixed-length sequence has no duplicate characters, solution is the 1-based
  index of the final character in the marker.
  """

  @doc "The start-of-packet marker is length 4."
  def part1([str]), do: solve(4, {4, to_charlist(str)})

  @doc "The start-of-packet marker is length 14."
  def part2([str]), do: solve(14, {14, to_charlist(str)})

  def solve(length, {i, chars}) do
    prefix = Enum.take(chars, length)
    if Enum.uniq(prefix) |> Enum.count == length, do: i, else: solve(length, {i + 1, tl(chars)})
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day6, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day6.main()

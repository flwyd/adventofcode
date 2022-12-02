#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/2

defmodule Day2 do
  @moduledoc """
  Input is two space-separated columns, A/B/C and X/Y/Z.
  A/B/C represents Rock/Paper/Scissors. An RPS game is scored with 1/2/3 points
  based on play plus 6 points for winning an 3 points for a tie.
  Output is the sum of scores for the second player ("mine").
  """

  @doc "X/Y/Z are Rock/Paper/Scissors plays."
  def part1(input) do
    input
    |> Enum.map(fn <<theirs, " ", mine>> -> {theirs - ?A, mine - ?X} end)
    |> Enum.map(&score/1)
    |> Enum.sum()
  end

  @doc "X/Y/Z are decisions to lose/tie/win, so decide what to play."
  def part2(input) do
    input
    |> Enum.map(fn <<theirs, " ", outcome>> -> {theirs - ?A, outcome} end)
    |> Enum.map(&choose_move/1)
    |> Enum.map(&score/1)
    |> Enum.sum()
  end

  defp score({theirs, mine}) do
    mine + 1 +
      case Integer.mod(mine - theirs, 3) do
        0 -> 3
        1 -> 6
        2 -> 0
      end
  end

  defp choose_move({theirs, outcome}), do: {theirs, Integer.mod(theirs + (outcome - ?Y), 3)}

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day2, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day2.main()

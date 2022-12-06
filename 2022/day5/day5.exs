#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/5

defmodule Day5 do
  @moduledoc """
  Input is two sections, separated by a blank line.  The first section is a
  vertically aligned set of stacks with upper-case letters in brackes like
  `[X]` for several lines, above an integer index from 1 to 9 in the actual
  input, 1 to 3 in the example.  These stacks are additionally separated by
  spaces, so they're 4 characters wide.  Lines in the second section are
  structured `"move X from Y to Z"` where X, Y, and Z are integers.
  The top X items from stack Y are moved on top of stack Z.
  """
  import Enum, only: [map: 2, reduce: 3]
  import String, only: [to_integer: 1]

  defmodule Move do
    defstruct count: 0, from: 0, to: 0
  end

  defmodule Input do
    defstruct stacks: %{}, count: 0, moves: []

    def parse(lines) do
      reduce(lines, %Input{}, &parse_line/2)
    end

    def parse_line("", input) do
      if input.count != Enum.count(input.stacks),
        do: raise("Expected #{input.count} input.stacks but got #{input.stacks}")

      input
    end

    def parse_line(<<"move ", rest::binary>>, input) do
      [count, "from", from, "to", to] = String.split(rest, " ", trim: true)
      move = %Move{count: to_integer(count), from: to_integer(from), to: to_integer(to)}
      Map.put(input, :moves, input.moves ++ [move])
    end

    def parse_line(<<" 1", rest::binary>>, input) do
      %Input{input | count: 1 + Enum.count(String.split(rest, " ", trim: true))}
    end

    def parse_line(crates, input) when is_binary(crates) do
      crates
      |> to_charlist
      |> Enum.with_index()
      |> Enum.filter(fn {char, _i} -> char in ?A..?Z end)
      |> reduce(input, fn {char, column}, acc ->
        stack = div(column + 3, 4)
        cur = Map.get(acc.stacks, stack, '')
        %Input{acc | stacks: Map.put(acc.stacks, stack, cur ++ [char])}
      end)
    end
  end

  @doc "Crates are moved one at a time from a stack."
  def part1(input), do: solve(input, &Enum.reverse/1)

  @doc "Crates are moved as a group from one stack to another."
  def part2(input), do: solve(input, &Function.identity/1)

  defp solve(input, order_crates) do
    %Input{stacks: stacks, count: _count, moves: moves} = Input.parse(input)

    moves
    |> reduce(stacks, &move_crates(&1, &2, order_crates))
    |> Enum.sort()
    |> map(fn {_k, v} -> hd(v) end)
    |> to_string()
  end

  defp move_crates(move, stacks, order_crates) do
    {crates, tail} = Enum.split(stacks[move.from], move.count)
    crates = order_crates.(crates)
    %{stacks | move.from => tail, move.to => crates ++ stacks[move.to]}
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day5, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day5.main()

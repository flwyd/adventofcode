#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/13

defmodule Day13 do
  @moduledoc """
  Input is pairs of nested lists of integers, paris separated by blank lines.
  A pair of lines is checked for well-ordering by comparing left to right.
  Comparison for integers: left < right is correct, left > right is not correct,
  and left = right continues checking the rest of the list.  This means that
  comparisons short-circuit.  Lists are compared pairwise, then lengths are
  compared by the same rules.  Comparing an integer to a list is the same as
  comparing a singleton list of that integer to the other list.
  """

  # TODO write a parser instead of using eval_string

  @doc "Sum the positions of pairs which are in the correct order."
  def part1(input) do
    input
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line -> elem(Code.eval_string(line), 0) end)
    |> Enum.chunk_every(2)
    |> Enum.map(&List.to_tuple/1)
    |> Enum.map(&compare_pair/1)
    |> Enum.with_index(1)
    |> Enum.filter(&(elem(&1, 0) == :correct))
    |> Enum.map(&elem(&1, 1))
    |> Enum.sum()
  end

  @doc "Insert `[[2]]` & `[[6]]`, sort the lines, and multiply 2 & 6 positions."
  def part2(input) do
    (["[[2]]", "[[6]]"] ++ input)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line -> elem(Code.eval_string(line), 0) end)
    |> Enum.sort(fn a, b -> compare_pair({a, b}) != :wrong end)
    |> Enum.with_index(1)
    |> Enum.filter(fn
      {[[2]], _} -> true
      {[[6]], _} -> true
      {_, _} -> false
    end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.product()
  end

  defp compare_pair({l, r}) when is_integer(l) and is_integer(r) and l < r, do: :correct
  defp compare_pair({l, r}) when is_integer(l) and is_integer(r) and l > r, do: :wrong
  defp compare_pair({l, r}) when is_integer(l) and is_integer(r) and l == r, do: :continue
  defp compare_pair({left, right}) when is_integer(left), do: compare_pair({[left], right})
  defp compare_pair({left, right}) when is_integer(right), do: compare_pair({left, [right]})

  defp compare_pair({left, right}) when is_list(left) and is_list(right) do
    Enum.zip_reduce(Stream.concat(left, [:stop]), Stream.concat(right, [:stop]), :continue, fn
      _, _, :wrong -> :wrong
      _, _, :correct -> :correct
      :stop, :stop, _acc -> :continue
      :stop, _, _acc -> :correct
      _, :stop, _acc -> :wrong
      l, r, :continue -> compare_pair({l, r})
    end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day13, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day13.main()

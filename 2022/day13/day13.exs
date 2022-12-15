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

  @doc "Sum the positions of pairs which are in the correct order."
  def part1(input) do
    input
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_line/1)
    |> Enum.chunk_every(2)
    |> Enum.map(fn [left, right] -> compare(left, right) end)
    |> Enum.with_index(1)
    |> Enum.filter(&(elem(&1, 0) == :correct))
    |> Enum.map(&elem(&1, 1))
    |> Enum.sum()
  end

  @doc "Insert `[[2]]` & `[[6]]`, sort the lines, and multiply 2 & 6 positions."
  def part2(input) do
    Enum.concat(["[[2]]", "[[6]]"], input)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_line/1)
    |> Enum.sort(fn a, b -> compare(a, b) != :wrong end)
    |> Enum.with_index(1)
    |> Enum.filter(fn
      {[[2]], _} -> true
      {[[6]], _} -> true
      {_, _} -> false
    end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.product()
  end

  defp compare(l, r) when is_integer(l) and is_integer(r) and l < r, do: :correct
  defp compare(l, r) when is_integer(l) and is_integer(r) and l > r, do: :wrong
  defp compare(l, r) when is_integer(l) and is_integer(r) and l == r, do: :continue
  defp compare(left, right) when is_integer(left), do: compare([left], right)
  defp compare(left, right) when is_integer(right), do: compare(left, [right])

  defp compare(left, right) when is_list(left) and is_list(right) do
    Enum.zip_reduce(Stream.concat(left, [:stop]), Stream.concat(right, [:stop]), :continue, fn
      _, _, :wrong -> :wrong
      _, _, :correct -> :correct
      :stop, :stop, _acc -> :continue
      :stop, _, _acc -> :correct
      _, :stop, _acc -> :wrong
      l, r, :continue -> compare(l, r)
    end)
  end

  defp parse_line(string) do
    {list, []} = parse_list(to_charlist(string))
    list
  end

  defp parse_list([?[ | rest]), do: parse_list_items(rest, [])

  defp parse_int(chars) do
    {digits, rest} = Enum.split_while(chars, fn x -> x in ?0..?9 end)
    int = Enum.reduce(digits, 0, fn d, acc -> 10 * acc + d - ?0 end)
    {int, rest}
  end

  defp parse_list_items([?[ | rest] = full, acc) do
    {list, more} = parse_list(full)
    parse_list_items(more, acc ++ [list])
  end

  defp parse_list_items([?] | rest], acc), do: {acc, rest}
  defp parse_list_items([?, | rest], acc), do: parse_list_items(rest, acc)

  defp parse_list_items(chars, acc) do
    {int, rest} = parse_int(chars)
    parse_list_items(rest, acc ++ [int])
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day13, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day13.main()

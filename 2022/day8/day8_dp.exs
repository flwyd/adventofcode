#! /usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/8

defmodule Day8_DP do
  @moduledoc """
  Input is a grid of numbers.  Visibility is possible in a cardinal direction
  if all intervening numbers are less than the subject number.

  This is a dynamic programming variation on the main O(n^3-ish) implementation
  in day8.exs.  Despite having techniccally loower complexity (something like
  O(n^2 + 40n), n is small enough that this implementation is actually
  _twice as slow_ as the other approach because n is pretty small.
  """

  @doc "Count the points visible from outside the grid."
  def part1(input) do
    {grid, maxrow, maxcol} = parse_grid(input)
    {left, right, top, bottom} = build_lrtb(grid, maxrow, maxcol)

    Enum.filter(grid, fn {{row, col}, val} ->
      Enum.map([left, right, top, bottom], &(!Map.has_key?(&1[{row, col}], val))) |> Enum.any?()
    end)
    |> Enum.count()
  end

  @doc """
  Score is the product of the number of visible points from a point; find the
  maximal score.
  """
  def part2(input) do
    {grid, maxrow, maxcol} = parse_grid(input)
    {left, right, top, bottom} = build_lrtb(grid, maxrow, maxcol)

    for {{row, col}, value} <- grid do
      Enum.product([
        row - Map.get(top[{row, col}], value, 0),
        Map.get(bottom[{row, col}], value, maxrow) - row,
        col - Map.get(left[{row, col}], value, 0),
        Map.get(right[{row, col}], value, maxcol) - col
      ])
    end
    |> Enum.max()
  end

  defp build_lrtb(grid, maxrow, maxcol) do
    {
      Enum.reduce(0..maxrow, %{}, fn row, acc ->
        Map.merge(acc, build_highest_table(for(col <- 0..maxcol, do: {row, col}), grid, :col))
      end),
      Enum.reduce(0..maxrow, %{}, fn row, acc ->
        Map.merge(acc, build_highest_table(for(col <- maxcol..0, do: {row, col}), grid, :col))
      end),
      Enum.reduce(0..maxcol, %{}, fn col, acc ->
        Map.merge(acc, build_highest_table(for(row <- 0..maxrow, do: {row, col}), grid, :row))
      end),
      Enum.reduce(0..maxcol, %{}, fn col, acc ->
        Map.merge(acc, build_highest_table(for(row <- maxrow..0, do: {row, col}), grid, :row))
      end)
    }
  end

  defp build_highest_table(points, grid, want) do
    {table, _} =
      Enum.reduce(points, {%{}, %{}}, fn {row, col}, {res, acc} ->
        {Map.put(res, {row, col}, acc),
         Enum.reduce(grid[{row, col}]..0, acc, fn val, acc2 ->
           Map.put(
             acc2,
             val,
             case want do
               :row -> row
               :col -> col
             end
           )
         end)}
      end)

    table
  end

  defp parse_grid(input) do
    grid =
      input
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {line, rownum}, accout ->
        String.split(line, "", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> Enum.with_index()
        |> Enum.reduce(accout, fn {cell, colnum}, accin ->
          Map.put(accin, {rownum, colnum}, cell)
        end)
      end)

    maxrow = Enum.count(input) - 1
    maxcol = String.length(List.first(input)) - 1
    {grid, maxrow, maxcol}
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day8_DP, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day8_DP.main()

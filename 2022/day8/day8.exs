#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/8

defmodule Day8 do
  @moduledoc """
  Input is a grid of numbers.  Visibility is possible in a cardinal direction
  if all intervening numbers are less than the subject number.
  """

  @doc "Count the points visible from outside the grid."
  def part1(input) do
    {grid, maxrow, maxcol} = parse_grid(input)

    Enum.count(
      for row <- 0..maxrow, col <- 0..maxcol, visible?({row, col}, maxrow, maxcol, grid), do: true
    )
  end

  @doc """
  Score is the product of the number of visible points from a point; find the
  maximal score.
  """
  def part2(input) do
    {grid, maxrow, maxcol} = parse_grid(input)

    for row <- 1..(maxrow - 1), col <- 1..(maxcol - 1) do
      score_visible({row, col}, maxrow, maxcol, grid)
    end
    |> Enum.max()
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

  defp visible?({row, col}, maxrow, maxcol, grid) do
    value = grid[{row, col}]

    Enum.any?([
      Enum.all?(0..(row - 1)//1, fn r -> grid[{r, col}] < value end),
      Enum.all?(0..(col - 1)//1, fn c -> grid[{row, c}] < value end),
      Enum.all?((row + 1)..maxrow//1, fn r -> grid[{r, col}] < value end),
      Enum.all?((col + 1)..maxcol//1, fn c -> grid[{row, c}] < value end)
    ])
  end

  defp score_visible({row, col}, maxrow, maxcol, grid) do
    value = grid[{row, col}]

    compare = fn r, c, acc ->
      if grid[{r, c}] < value, do: {:cont, acc + 1}, else: {:halt, acc + 1}
    end

    Enum.product([
      Enum.reduce_while((row - 1)..0//-1, 0, fn r, acc -> compare.(r, col, acc) end),
      Enum.reduce_while((col - 1)..0//-1, 0, fn c, acc -> compare.(row, c, acc) end),
      Enum.reduce_while((row + 1)..maxrow//1, 0, fn r, acc -> compare.(r, col, acc) end),
      Enum.reduce_while((col + 1)..maxcol//1, 0, fn c, acc -> compare.(row, c, acc) end)
    ])
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day8, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day8.main()

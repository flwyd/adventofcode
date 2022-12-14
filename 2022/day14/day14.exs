#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/14

defmodule Day14 do
  @moduledoc """
  Input is a series of paths like `a,b -> c,d -> e,f` with each pair defining a
  horizontal or vertical wall.  Grains of sand are dropped from position `500,0`
  and fall, in preference order, straight down, diagonal left+down, or diagnoal
  right+down, until the grain is blocked in all three positions.
  """

  @doc "Count the number of grains until one won't be blocked by anything."
  def part1(input), do: solve(input, 1)

  @doc """
  There's an infinite floor 2 steps past the lowest y value in the input.
  Count the number of grains until they've stacked all the way to `500,0`.
  """
  def part2(input), do: solve(input, 2)

  def solve(input, part) do
    start_grid = Enum.reduce(input, MapSet.new(), &parse_line/2)
    max_y = Enum.map(start_grid, &elem(&1, 1)) |> Enum.max()

    Enum.reduce_while(
      Stream.cycle([{500, 0}]),
      {start_grid, 0},
      fn start, {grid, count} ->
        if MapSet.member?(grid, start) do
          {:halt, count}
        else
          {landed, newgrid} = drop(start, grid, max_y, part)
          if landed, do: {:cont, {newgrid, count + 1}}, else: {:halt, count}
        end
      end
    )
  end

  defp drop({_x, y}, grid, max_y, 1 = _part) when y > max_y, do: {false, grid}
  defp drop({x, y}, grid, max_y, 2 = _part) when y > max_y, do: {true, MapSet.put(grid, {x, y})}

  defp drop({x, y} = point, grid, max_y, part) do
    case possible_moves(point, grid) do
      [] -> {true, MapSet.put(grid, {x, y})}
      [first | _] -> drop(first, grid, max_y, part)
    end
  end

  defp possible_moves({x, y}, grid) do
    Enum.map([{0, 1}, {-1, 1}, {1, 1}], fn {dx, dy} -> {x + dx, y + dy} end)
    |> Enum.reject(&MapSet.member?(grid, &1))
  end

  defp parse_line(line, into) do
    String.split(line, " -> ")
    |> Enum.map(fn point ->
      [x, y] = String.split(point, ",")
      {String.to_integer(x), String.to_integer(y)}
    end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(into, fn
      [{ax, y}, {bx, y}], acc -> Enum.reduce(ax..bx, acc, &MapSet.put(&2, {&1, y}))
      [{x, ay}, {x, by}], acc -> Enum.reduce(ay..by, acc, &MapSet.put(&2, {x, &1}))
    end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day14, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day14.main()

#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/15

defmodule Day15 do
  @moduledoc """
  Input is lines defining the x,y position of sensors and their closest beacon.
  Beacons can be close to more than one sensor.  Problem parameters differ for
  handling example data and actual data.
  """
  import String, only: [to_integer: 1]

  @huge 10_000_000
  @doc "Count positions in row 10/2 million that cannot have a hidden beacon."
  def part1(input) do
    {pairs, datafile} = parse_input(input)
    row = if datafile == :example, do: 10, else: 2_000_000

    [first | ranges] =
      Enum.filter(pairs, fn {{sx, _} = sensor, beacon} -> in_zone?(sensor, beacon, {sx, row}) end)
      |> Enum.reduce([], fn {sensor, beacon}, acc ->
        [x_range(sensor, beacon, row, -@huge, @huge) | acc]
      end)
      |> Enum.sort()

    {_, count} =
      Enum.reduce(ranges, {first, Range.size(first)}, fn curlo..curhi, {prevlo..prevhi, count} ->
        if prevhi >= curhi do
          {prevlo..prevhi, count}
        else
          clamped = max(curlo, prevhi + 1)..curhi
          {clamped, count + Range.size(clamped)}
        end
      end)

    count -
      (Enum.map(pairs, fn {_, {_, y}} -> y end)
       |> Enum.filter(&(&1 == row))
       |> Enum.uniq()
       |> Enum.count())
  end

  @doc "Find the one x,y coordinate where a hidden beacon could be present."
  def part2(input) do
    {pairs, datafile} = parse_input(input)
    max_coord = if datafile == :example, do: 20, else: 4_000_000
    {x, y} = find_gap(pairs, max_coord, 0, 0)
    x * 4_000_000 + y
  end

  defp find_gap(pairs, max_coord, col, row) do
    if row > max_coord || col > max_coord, do: raise("#{col},#{row} too big")

    case Enum.find(pairs, fn {sensor, beacon} -> in_zone?(sensor, beacon, {col, row}) end) do
      nil ->
        {col, row}

      {s, b} ->
        with _start..edge = x_range(s, b, row, 0, max_coord) do
          if edge == max_coord,
            do: find_gap(pairs, max_coord, 0, row + 1),
            else: find_gap(pairs, max_coord, edge + 1, row)
        end
    end
  end

  defp in_zone?(sensor, beacon, point), do: distance(sensor, beacon) >= distance(sensor, point)

  defp x_range({sx, sy} = sensor, beacon, row, min_coord, max_coord) do
    dist = distance(sensor, beacon)
    max(sx - (dist - abs(sy - row)), min_coord)..min(sx + (dist - abs(sy - row)), max_coord)
  end

  defp distance({ax, ay}, {bx, by}), do: abs(ax - bx) + abs(ay - by)

  defp parse_input(input) do
    pairs = Enum.map(input, &parse_line/1)
    max_x = Enum.map(pairs, &elem(elem(&1, 0), 0)) |> Enum.max()
    {pairs, if(max_x < 100, do: :example, else: :actual)}
  end

  @pattern ~r/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/
  defp parse_line(line) do
    [_, sx, sy, bx, by] = Regex.run(@pattern, line)
    {{to_integer(sx), to_integer(sy)}, {to_integer(bx), to_integer(by)}}
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day15, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day15.main()

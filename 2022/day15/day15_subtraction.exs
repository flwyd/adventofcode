#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/15

defmodule Day15Subtraction do
  @moduledoc """
  Input is lines defining the x,y position of sensors and their closest beacon.
  Beacons can be close to more than one sensor.  Problem parameters differ for
  handling example data and actual data.
  """
  import String, only: [to_integer: 1]

  defmodule Rectangle do
    defstruct top: 0, bottom: 0, left: 0, right: 0

    def new({center_x, center_y}, manhattan_radius) do
      {left, top} = point_from_grid({center_x - manhattan_radius, center_y})
      {right, bottom} = point_from_grid({center_x + manhattan_radius, center_y})
      %Rectangle{top: top, bottom: bottom, left: left, right: right}
    end

    def subtract(from, hole) do
      cond do
        Range.disjoint?(x_range(from), x_range(hole)) && Range.disjoint?(y_range(from), y_range(hole)) -> [from]
        true -> List.flatten([
            left_remainder(from, hole), right_remainder(from, hole), top_remainder(from, hole), bottom_remainder(from, hole)
        ])
      end
    end

    def left_remainder(%Rectangle{left: fl}, %Rectangle{left: hl}) when fl >= hl, do: []
    def left_remainder(%Rectangle{top: ft, bottom: fb, left: fl},
      %Rectangle{top: ht, bottom: hb, left: hl}) when ht <= ft and hb >= fb do
        [%Rectangle{left: fl, right: hl, top: ft, bottom: fb}]
      end
    def left_remainder(%Rectangle{top: ft, bottom: fb, left: fl},
      %Rectangle{top: ht, bottom: hb, left: hl}) do
        [ %Rectangle{left: fl, right: hl, top: max(ft, ht), bottom: min(fb, hb)}] ++
          if ft < ht, do: [%Rectangle{left: fl, right: hl, top: ft, bottom: ht}], else: [] ++
          if fb > hb, do: [%Rectangle{left: fl, right: hl, top: hb, bottom: fb}], else: []
      end

    def right_remainder(%Rectangle{right: fr}, %Rectangle{right: hr}) when fr <= hr, do: []
    def right_remainder(%Rectangle{top: ft, bottom: fb, right: fr},
      %Rectangle{top: ht, bottom: hb, right: hr}) when ht <= ft and hb >= fb do
        [%Rectangle{left: hr, right: fr, top: ft, bottom: fb}]
      end
    def right_remainder(%Rectangle{top: ft, bottom: fb, right: fr},
      %Rectangle{top: ht, bottom: hb, right: hr}) do
        [ %Rectangle{left: hr, right: fr, top: max(ft, ht), bottom: min(fb, hb)}] ++
          if ft < ht, do: [%Rectangle{left: hr, right: fr, top: ft, bottom: ht}], else: [] ++
          if fb > hb, do: [%Rectangle{left: hr, right: fr, top: hb, bottom: fb}], else: []
      end

    def top_remainder(%Rectangle{top: ft}, %Rectangle{top: ht}) when ft >= ht, do: []
    def top_remainder(%Rectangle{top: ft, left: fl, right: fr},
      %Rectangle{top: ht, left: hl, right: hr}) do
        [%Rectangle{top: ft, bottom: ht, left: max(fl, hl), right: max(fr, hr)}]
      end

    def bottom_remainder(%Rectangle{bottom: fb}, %Rectangle{bottom: hb}) when fb <= hb, do: []
    def bottom_remainder(%Rectangle{bottom: fb, left: fl, right: fr},
      %Rectangle{bottom: hb, left: hl, right: hr}) do
        [%Rectangle{top: fb, bottom: hb, left: max(fl, hl), right: max(fr, hr)}]
      end

    def point_from_grid({x, y}), do: {x-y, x+y}
    def point_to_grid({x, y}), do: {div(x+y, 2), div(y-x, 2)}

    defp x_range(rect), do: rect.left..rect.right
    defp y_range(rect), do: rect.top..rect.bottom
  end

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
    success = Runner.main(Day15Subtraction, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day15Subtraction.main()


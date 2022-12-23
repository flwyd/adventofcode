#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/23

defmodule Day23 do
  @moduledoc """
  Input is a grid of elf (`#`) and space (`.`) positions.  Each round the elves
  stay put if they aren't adjacent to any elf, then move in a cardinal direction
  if there are no elves in the three cells in that direction.  Elves don't move
  if they would collide.  The direction preference cycles each round.
  """

  @north {-1, 0}
  @south {1, 0}
  @east {0, 1}
  @west {0, -1}
  @ne {-1, 1}
  @nw {-1, -1}
  @se {1, 1}
  @sw {1, -1}
  @stay {0, 0}
  @northern {@north, [@north, @ne, @nw]}
  @southern {@south, [@south, @se, @sw]}
  @western {@west, [@west, @nw, @sw]}
  @eastern {@east, [@east, @ne, @se]}
  @stay_put {@stay, [@stay]}
  @all_dirs [@nw, @north, @ne, @east, @se, @south, @sw, @west]

  @doc "Count the empty spaces after 10 rounds."
  def part1(input) do
    points = parse_input(input, 1, MapSet.new())
    pref_cycle = Stream.cycle([@northern, @southern, @western, @eastern])

    points =
      Enum.reduce(1..10, points, fn round, points ->
        run_round(points, round_prefs(round, pref_cycle))
      end)

    if Enum.count(points) < 10, do: print_points(points)
    bounding_rectangle_size(points) - Enum.count(points)
  end

  @doc "Identify the first round when the elves have all stopped moving."
  def part2(input) do
    points = parse_input(input, 1, MapSet.new())
    pref_cycle = Stream.cycle([@northern, @southern, @western, @eastern])

    Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), points, fn round, points ->
      next = run_round(points, round_prefs(round, pref_cycle))
      if MapSet.equal?(points, next), do: {:halt, round}, else: {:cont, next}
    end)
  end

  defp run_round(points, prefs) do
    Enum.reduce(points, %{}, fn point, acc ->
      dir = pick_move(point, points, prefs)
      Map.update(acc, move(point, dir), [point], fn rest -> [point | rest] end)
    end)
    |> Enum.map(fn
      {dest, [_cur]} -> [dest]
      {_, several} -> several
    end)
    |> List.flatten()
    |> Enum.into(MapSet.new())
  end

  defp round_prefs(round, pref_cycle),
    do: Stream.drop(pref_cycle, rem(round - 1, 4)) |> Stream.take(4) |> Enum.into([])

  defp bounding_rectangle(points) do
    {top, bottom} = points |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
    {left, right} = points |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
    {top, bottom, left, right}
  end

  defp bounding_rectangle_size(points) do
    {top, bottom, left, right} = bounding_rectangle(points)
    (bottom - top + 1) * (right - left + 1)
  end

  defp pick_move(point, points, prefs) do
    if Enum.all?(@all_dirs, fn dir -> empty?(move(point, dir), points) end) do
      @stay
    else
      {dir, _} =
        Enum.find(prefs, @stay_put, fn {_, dirs} ->
          dirs |> Enum.map(&move(point, &1)) |> Enum.all?(&empty?(&1, points))
        end)

      dir
    end
  end

  defp empty?(point, points), do: not MapSet.member?(points, point)

  defp move({row, col}, {drow, dcol}), do: {row + drow, col + dcol}

  defp parse_input([], _row, acc), do: acc

  defp parse_input([line | rest], row, acc) do
    acc =
      String.to_charlist(line)
      |> Enum.with_index()
      |> Enum.filter(fn {c, _i} -> c == ?# end)
      |> Enum.map(fn {_, col} -> {row, col} end)
      |> Enum.into(acc)

    parse_input(rest, row + 1, acc)
  end

  defp print_points(points) do
    {top, bottom, left, right} = bounding_rectangle(points)

    for row <- -top..bottom do
      IO.puts(
        :stderr,
        Enum.map(left..right, fn col ->
          if MapSet.member?(points, {row, col}), do: ?#, else: ?.
        end)
      )
    end
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day23, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day23.main()

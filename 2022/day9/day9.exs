#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/9

defmodule Day9 do
  @moduledoc """
  Input is a series of "letter number" pairs.  Letters are L/R/U/D for
  left/right/up/down, numbers are the steps for the head knot on a rope to move
  in that direction, one step at a time.  Subsequent knots follow the knot in
  front of them by closing the gap when one develops.
  """

  @doc "The rope has one tail knot."
  def part1(input), do: record_path(input, 1) |> elem(2) |> Enum.count()

  @doc "The rope has nine tail knots."
  def part2(input), do: record_path(input, 9) |> elem(2) |> Enum.count()

  @origin {0, 0}
  defp record_path(input, num_tails) do
    moves = Enum.map(input, &expand_line/1) |> List.flatten()

    Enum.reduce(
      moves,
      {@origin, List.duplicate(@origin, num_tails), MapSet.new([@origin])},
      fn {drow, dcol}, {head, tail, acc} ->
        newhead = move_head({drow, dcol}, head)
        newtail = move_chain(newhead, tail)
        {newhead, newtail, MapSet.put(acc, List.last(newtail))}
      end
    )
  end

  defp expand_line(<<dir, " ", amount::binary>>) do
    List.duplicate(
      case dir do
        ?U -> {-1, 0}
        ?D -> {1, 0}
        ?L -> {0, -1}
        ?R -> {0, 1}
      end,
      String.to_integer(amount)
    )
  end

  defp move_chain(_head, []), do: []

  defp move_chain(head, [tail | rest]) do
    newtail = move_tail(head, tail)
    [newtail | move_chain(newtail, rest)]
  end

  defp move_head({drow, dcol}, {row, col}), do: {row + drow, col + dcol}

  defp move_tail({headrow, headcol}, {tailrow, tailcol}) do
    {rowdiff, coldiff} = {headrow - tailrow, headcol - tailcol}

    case {abs(rowdiff), abs(coldiff)} do
      # {0,0}, {1,0}, {0,1}, {1,1} mean tail is next to head, so no movement
      {r, c} when r < 2 and c < 2 ->
        {tailrow, tailcol}

      {0, 2} ->
        {tailrow, tailcol + signum(coldiff)}

      {2, 0} ->
        {tailrow + signum(rowdiff), tailcol}

      # {2,1}, {1, 2}, {2,2} do the same; this also catches the impossible {3, 0}, {0, 4} etc.
      {r, c} when r + c == 3 or r + c == 4 ->
        {tailrow + signum(rowdiff), tailcol + signum(coldiff)}
    end
  end

  defp signum(0), do: 0
  defp signum(i) when i < 0, do: -1
  defp signum(i) when i > 0, do: 1

  def print_path(device \\ :stderr, input) do
    {head, tail, points} = record_path(input, 9)
    {minrow, maxrow} = Enum.min_max(Enum.map(Enum.concat([[head], tail, points]), &elem(&1, 0)))
    {mincol, maxcol} = Enum.min_max(Enum.map(Enum.concat([[head], tail, points]), &elem(&1, 1)))

    for row <- minrow..maxrow do
      IO.puts(
        device,
        Enum.join(
          for col <- mincol..maxcol do
            cond do
              {row, col} == head -> 'H'
              {row, col} in tail -> [?1 + Enum.find_index(tail, &(&1 == {row, col}))]
              {row, col} == @origin -> 's'
              {row, col} in points -> '#'
              true -> '.'
            end
          end
        )
      )
    end

    :ok
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day9, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day9.main()

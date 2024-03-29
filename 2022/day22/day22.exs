#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/22

defmodule Day22 do
  @moduledoc """
  Input is a grid of spaces, dots, and octothorpes indicating invalid, open,
  and blocked positions respectively.  Then a blank line and then one line with
  a series of numbers and L/R letters.  Start on the first open position in the
  first row facing right.  For each number in the final line, move that many
  steps forward or until bumping into a wall.  For each L or R, rotate 90°
  widdershins or deosil respectively.  At the end of movement the result is
  1000 * row + 4 * col + dir where dir is 0 for right and increases deosil by 1.
  """
  @right {0, 1}
  @down {1, 0}
  @left {0, -1}
  @up {-1, 0}

  @doc "When moving into an invalid space, at the edges wrap like Pac-Man."
  def part1(input) do
    {grid, {max_row, max_col}, moves} = parse_input(input)
    start_col = Enum.find(1..max_col, fn c -> Map.has_key?(grid, {1, c}) end)
    start_face = @right
    traverse = %{{1, start_col} => start_face}

    {{row, col}, face, traverse} =
      Enum.reduce(moves, {{1, start_col}, start_face, traverse}, fn
        :left, {pos, face, traverse} ->
          face = rotate(face, :left)
          {pos, face, Map.put(traverse, pos, face)}

        :right, {pos, face, traverse} ->
          face = rotate(face, :right)
          {pos, face, Map.put(traverse, pos, face)}

        num, {pos, {dr, dc} = face, traverse} ->
          {final, traverse} =
            Enum.reduce_while(1..num, {pos, traverse}, fn _, {{row, col} = pos, traverse} ->
              next = maybe_wrap({row + dr, col + dc}, face, {max_row, max_col}, grid)

              case Map.get(grid, next, :nope) do
                :open -> {:cont, {next, Map.put(traverse, next, face)}}
                :wall -> {:halt, {pos, traverse}}
              end
            end)

          {final, face, traverse}
      end)

    if max_row < 10, do: print_traverse(traverse, grid, max_row, max_col)
    password(row, col, face)
  end

  @doc "Input grid is faces of a cube, at the edges wrap in 3D space."
  def part2(input) do
    {grid, {max_row, max_col}, moves} = parse_input(input)
    wrap = if max_row < 20, do: example_cube_wrap(), else: actual_cube_wrap()
    # make sure the cube wrapping edges are valid
    for {{from, ff} = f, {to, tf} = t} <- wrap do
      if !Map.has_key?(grid, to), do: raise("Wrap from #{inspect(f)} to #{inspect(t)} missing")
      if Map.has_key?(grid, {from, ff}), do: raise("Wrap from #{inspect(f)} already in grid")
      rev = rotate(rotate(tf, :left), :left)
      # wrapping will raise an error if an edge doesn't match something
      {rev_pos, rev_face} = maybe_wrap_cube(to, rev, grid, wrap)
      maybe_wrap_cube(rev_pos, rev_face, grid, wrap)
    end

    start_col = Enum.find(1..max_col, fn c -> Map.has_key?(grid, {1, c}) end)
    start_face = @right
    traverse = %{{1, start_col} => start_face}

    {{row, col}, face, traverse} =
      Enum.reduce(moves, {{1, start_col}, start_face, traverse}, fn
        :left, {pos, face, traverse} ->
          face = rotate(face, :left)
          {pos, face, Map.put(traverse, pos, face)}

        :right, {pos, face, traverse} ->
          face = rotate(face, :right)
          {pos, face, Map.put(traverse, pos, face)}

        num, {pos, face, traverse} ->
          {final, final_face, traverse} =
            Enum.reduce_while(1..num, {pos, face, traverse}, fn _, {pos, face, traverse} ->
              {next, new_face} = maybe_wrap_cube(pos, face, grid, wrap)

              case Map.get(grid, next, :nope) do
                :open -> {:cont, {next, new_face, Map.put(traverse, next, new_face)}}
                :wall -> {:halt, {pos, face, traverse}}
              end
            end)

          {final, final_face, traverse}
      end)

    if max_row < 100, do: print_traverse(traverse, grid, max_row, max_col)
    password(row, col, face)
  end

  defp parse_input(input, row_max_col \\ {1, 0}, grid \\ %{})

  defp parse_input(["" | rest], {max_row, max_col}, grid),
    do: parse_input(rest, {max_row - 1, max_col}, grid)

  defp parse_input([last], row_max_col, grid) do
    moves =
      Regex.split(~r/(L|R|\d+)/, last, include_captures: true, trim: true)
      |> Enum.map(fn
        "L" -> :left
        "R" -> :right
        num -> String.to_integer(num)
      end)

    {grid, row_max_col, moves}
  end

  defp parse_input([head | rest], {row, max_col}, grid) do
    grid =
      String.to_charlist(head)
      |> Enum.with_index(1)
      |> Enum.reject(fn {char, _i} -> char === ?\s end)
      |> Enum.map(fn
        {?., i} -> {{row, i}, :open}
        {?#, i} -> {{row, i}, :wall}
      end)
      |> Enum.into(grid)

    parse_input(rest, {row + 1, max(max_col, String.length(head) + 1)}, grid)
  end

  defp password(row, col, face) do
    face_score =
      case face do
        @right -> 0
        @down -> 1
        @left -> 2
        @up -> 3
      end

    1000 * row + 4 * col + face_score
  end

  defp rotate({drow, dcol}, :left), do: {-1 * dcol, drow}
  defp rotate({drow, dcol}, :right), do: {dcol, -1 * drow}

  defp maybe_wrap_cube({row, col}, {drow, dcol} = face, grid, wrap) do
    next = {row + drow, col + dcol}

    if Map.has_key?(grid, next) do
      {next, face}
    else
      case Map.get(wrap, {next, face}) do
        nil ->
          raise "Could not wrap from #{row},#{col} facing #{drow},#{dcol}"

        {dest, face} ->
          if Map.has_key?(grid, dest),
            do: {dest, face},
            else: raise("Wrapped from #{row},#{col} to #{inspect({dest, face})} not in grid")
      end
    end
  end

  defp maybe_wrap(pos, face, {max_row, max_col}, grid) do
    if Map.has_key?(grid, pos) do
      pos
    else
      {idx, range} =
        case face do
          @down -> {0, 1..max_row}
          @up -> {0, max_row..1}
          @right -> {1, 1..max_col}
          @left -> {1, max_row..1}
        end

      Enum.map(range, fn i -> put_elem(pos, idx, i) end)
      |> Enum.find(fn pos -> Map.has_key?(grid, pos) end)
    end
  end

  # The example input has a different 2D cube layout than the actual input, so hardcode edges
  # differently for both.  This means twice as many opportunities for errors!
  defp example_cube_wrap() do
    wraps = %{}
    ### side 1 from row 1 to 4 and col 9 to 12 ###
    # side 1 going right goes to 6 going left
    wraps =
      Enum.map(1..4, fn row -> {{{row, 13}, @right}, {{13 - row, 16}, @left}} end)
      |> Enum.into(wraps)

    # side 1 going up goes to 2 going down
    wraps =
      Enum.map(9..12, fn col -> {{{0, col}, @up}, {{5, col - 5}, @down}} end) |> Enum.into(wraps)

    # side 1 going left goes to 3 going down
    wraps =
      Enum.map(1..4, fn row -> {{{row, 8}, @left}, {{5, 4 + row}, @down}} end) |> Enum.into(wraps)

    ### side 2 from row 5 to 9 and col 1 to 4 ###
    # side 2 going left goes to 6 going up
    wraps =
      Enum.map(5..8, fn row -> {{{row, 0}, @left}, {{12, 6 + row}, @up}} end) |> Enum.into(wraps)

    # side 2 going up goes to 1 going down
    wraps =
      Enum.map(1..4, fn col -> {{{4, col}, @up}, {{1, 13 - col}, @down}} end) |> Enum.into(wraps)

    # side 2 going down goes to 5 going up
    wraps =
      Enum.map(1..4, fn col -> {{{9, col}, @down}, {{12, 13 - col}, @up}} end) |> Enum.into(wraps)

    ### side 3 from row 5 to 8 and col 5 to 8 ###
    # side 3 going up goes to 1 going right
    wraps =
      Enum.map(5..8, fn col -> {{{4, col}, @up}, {{col - 4, 9}, @right}} end) |> Enum.into(wraps)

    # side 3 going down goes to 5 going left
    wraps =
      Enum.map(5..8, fn col -> {{{9, col}, @down}, {{12 - col, 9}, @up}} end) |> Enum.into(wraps)

    ### side 4 from row 5 to 8 and col 9 to 12 ###
    # side 4 going right goes to 6 going down
    wraps =
      Enum.map(5..8, fn row -> {{{row, 13}, @right}, {{9, 21 - row}, @down}} end)
      |> Enum.into(wraps)

    ### side 5 from row 9 to 12 and col 9 to 12 ###
    # side 5 going left goes to 3 going up
    wraps =
      Enum.map(9..12, fn row -> {{{row, 8}, @left}, {{8, 17 - row}, @up}} end) |> Enum.into(wraps)

    # side 5 going down goes to 2 going up
    wraps =
      Enum.map(9..12, fn col -> {{{13, col}, @down}, {{8, 13 - col}, @up}} end)
      |> Enum.into(wraps)

    ### side 6 from row 9 to 12 and col 13 to 16 ###
    # side 6 going right goes to 1 going left
    wraps =
      Enum.map(9..12, fn row -> {{{row, 17}, @right}, {{13 - row, 12}, @left}} end)
      |> Enum.into(wraps)

    # side 6 going up goes to 4 going left
    wraps =
      Enum.map(13..16, fn col -> {{{8, col}, @up}, {{21 - col, 12}, @left}} end)
      |> Enum.into(wraps)

    # side 6 going down goes to 2 going right
    wraps =
      Enum.map(13..16, fn col -> {{{13, col}, @down}, {{21 - col, 1}, @right}} end)
      |> Enum.into(wraps)

    wraps
  end

  # My input square (and apparenty everyone else's) has 50x50 sides and is flattened like
  #     222 111
  #     222 111
  #     222 111
  #
  #     333
  #     333
  #     333
  #
  # 555 444
  # 555 444
  # 555 444
  #
  # 666
  # 666
  # 666
  defp actual_cube_wrap() do
    wraps = %{}
    ### side 1 from row 1 to 50 and col 101 to 150 ###
    # side 1 going right goes to 4 going left
    wraps =
      Enum.map(1..50, fn row -> {{{row, 151}, @right}, {{151 - row, 100}, @left}} end)
      |> Enum.into(wraps)

    # side 1 going up goes to 6 going up
    wraps =
      Enum.map(101..150, fn col -> {{{0, col}, @up}, {{200, col - 100}, @up}} end)
      |> Enum.into(wraps)

    # side 1 going down goes to 3 going left
    wraps =
      Enum.map(101..150, fn col -> {{{51, col}, @down}, {{col - 50, 100}, @left}} end)
      |> Enum.into(wraps)

    ### side 2 from row 1 to 50 and col 51 to 100 ###
    # side 2 going left goes to 5 going right
    wraps =
      Enum.map(1..50, fn row -> {{{row, 50}, @left}, {{151 - row, 1}, @right}} end)
      |> Enum.into(wraps)

    # side 2 going up goes to 6 going right
    wraps =
      Enum.map(51..100, fn col -> {{{0, col}, @up}, {{100 + col, 1}, @right}} end)
      |> Enum.into(wraps)

    ### side 3 from row 51 to 100 and col 51 to 100 ###
    # side 3 going left goes to 5 going down
    wraps =
      Enum.map(51..100, fn row -> {{{row, 50}, @left}, {{101, row - 50}, @down}} end)
      |> Enum.into(wraps)

    # side 3 going right goes to 1 going up
    wraps =
      Enum.map(51..100, fn row -> {{{row, 101}, @right}, {{50, 50 + row}, @up}} end)
      |> Enum.into(wraps)

    ### side 4 from row 101 to 150 and col 51 to 100 ###
    # side 4 going right goes to 1 going left
    wraps =
      Enum.map(101..150, fn row -> {{{row, 101}, @right}, {{151 - row, 150}, @left}} end)
      |> Enum.into(wraps)

    # side 4 going down goes to 6 going left
    wraps =
      Enum.map(51..100, fn col -> {{{151, col}, @down}, {{100 + col, 50}, @left}} end)
      |> Enum.into(wraps)

    ### side 5 from row 101 to 150 and col 1 to 50 ###
    # side 5 going left goes to 2 going right
    wraps =
      Enum.map(101..150, fn row -> {{{row, 0}, @left}, {{151 - row, 51}, @right}} end)
      |> Enum.into(wraps)

    # side 5 going up goes to 3 going right
    wraps =
      Enum.map(1..50, fn col -> {{{100, col}, @up}, {{50 + col, 51}, @right}} end)
      |> Enum.into(wraps)

    ### side 6 from row 151 to 200 and col 1 to 50 ###
    # side 6 going right goes to 4 going up
    wraps =
      Enum.map(151..200, fn row -> {{{row, 51}, @right}, {{150, row - 100}, @up}} end)
      |> Enum.into(wraps)

    # side 6 going down goes to 1 going down
    wraps =
      Enum.map(1..50, fn col -> {{{201, col}, @down}, {{1, 100 + col}, @down}} end)
      |> Enum.into(wraps)

    # side 6 going left goes to 2 going down
    wraps =
      Enum.map(151..200, fn row -> {{{row, 0}, @left}, {{1, row - 100}, @down}} end)
      |> Enum.into(wraps)

    wraps
  end

  defp print_traverse(t, grid, max_row, max_col) do
    for row <- 1..max_row do
      chars =
        for col <- 1..max_col do
          case {Map.get(t, {row, col}), Map.get(grid, {row, col}, :nope)} do
            {nil, :nope} -> ?\s
            {nil, :open} -> ?.
            {nil, :wall} -> ?#
            {face, _} -> face_char(face)
          end
        end

      IO.puts(:stderr, chars)
    end
  end

  defp face_char(@down), do: ?v
  defp face_char(@up), do: ?^
  defp face_char(@right), do: ?>
  defp face_char(@left), do: ?<

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day22, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day22.main()

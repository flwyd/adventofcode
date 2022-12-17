#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/17

defmodule Day17 do
  @moduledoc """
  Input is a single line with `<` and `>` characters indicating a jet blows left
  or right respectively.  Six Tetris-shaped rocks fall in a cycle, starting with
  the bottom part 4 rows above the top of the stack of rocks.  At each step, the
  jet blows the rock one place to the left or right (cycling through its `<>`
  characters) unless doing so would run into a wall (only 7 available spaces
  horizontally) or another piece of rock.  After the possible sideways step, the
  rock moves down one, unless doing so would run into a rock or the floor,
  in which case the next iteration starts.
  """
  defmodule Jetstream do
    defstruct line: "", index: 0

    def new(line), do: %Jetstream{line: line}

    @left {-1, 0}
    @right {1, 0}
    def next_move(%Jetstream{line: l, index: i} = jets) do
      move =
        case String.at(l, i) do
          "<" -> @left
          ">" -> @right
        end

      {struct!(jets, index: rem(i + 1, String.length(l))), move}
    end
  end

  @rock_shapes [
    # horizontal line: _
    [{2, -4}, {3, -4}, {4, -4}, {5, -4}],
    # plus: +
    [{3, -4}, {2, -5}, {3, -5}, {4, -5}, {3, -6}],
    # corner: J
    [{2, -4}, {3, -4}, {4, -4}, {4, -5}, {4, -6}],
    # vertical line: |
    [{2, -4}, {2, -5}, {2, -6}, {2, -7}],
    # square: #
    [{2, -4}, {3, -4}, {2, -5}, {3, -5}]
  ]

  @small_num 2022
  @doc "Compute the stack height after 2022 iterations"
  def part1(input) do
    rocks = Enum.take(Stream.cycle(@rock_shapes), @small_num)
    [line] = input

    {height, stack, _jets} =
      Enum.reduce(rocks, {0, [], Jetstream.new(line)}, fn rock, {height, stack, jets} ->
        drop_rock(rock, height, stack, jets)
      end)

    IO.puts(:stderr, "top 25 of stack are ")
    print_stack(Enum.take(stack, 25))
    height
  end

  # Intuition for magic constant of 8: it's enough for two vertical bars to slide down into a slot
  # without poking above the current height, and it seems unlikely there'd be that large of a gap
  # given that we're cycling through wider pieces.  This isn't very rigorous, though.
  @look_depth 8
  @big_num 1_000_000_000_000
  @doc "Compute the stack height after one trillion iterations"
  def part2(input) do
    rocks = Stream.cycle(@rock_shapes)
    [line] = input
    jets = Jetstream.new(line)
    cache = :ets.new(:cache, [:set])

    {height, stack, _jets, _i} =
      Enum.reduce_while(rocks, {0, [], jets, 0}, fn rock, {height, stack, jets, i} ->
        if i == @big_num do
          {:halt, {height, stack, jets, i}}
        else
          key = {rem(i, 6), jets.index, Enum.take(stack, @look_depth)}

          {full_height, iter} =
            if @big_num - i <= String.length(jets.line) do
              {height, i}
            else
              case :ets.lookup(cache, key) do
                [] ->
                  true = :ets.insert_new(cache, {key, {i, height}})
                  {height, i}

                [{_, {prev_i, prev_height}}] ->
                  with gap <- i - prev_i, chunk_height = height - prev_height do
                    factor = div(@big_num - i, gap)
                    new_i = i + gap * factor
                    new_height = height + chunk_height * factor
                    {new_height, new_i}
                  end
              end
            end

          {:cont, Tuple.append(drop_rock(rock, full_height, stack, jets), iter + 1)}
        end
      end)

    IO.puts(:stderr, "top 25 of stack are ")
    print_stack(Enum.take(stack, 25))
    :ets.delete(cache)
    height
  end

  @down {0, 1}
  defp drop_rock(rock, height, stack, jets) do
    {moved, jets} =
      Enum.reduce_while(Stream.cycle([nil]), {rock, jets}, fn nil, {rock, jets} ->
        {jets, move} = Jetstream.next_move(jets)
        shifted = move(rock, move)
        r = if allowed?(shifted, height, stack), do: shifted, else: rock
        down = move(r, @down)
        if allowed?(down, height, stack), do: {:cont, {down, jets}}, else: {:halt, {r, jets}}
      end)

    {height, stack} = place_rock(moved, height, stack)
    {height, stack, jets}
  end

  defp move(rock, {dx, dy}), do: Enum.map(rock, fn {x, y} -> {x + dx, y + dy} end)

  defp allowed?(rock, height, stack) do
    !Enum.any?(rock, fn {x, y} -> x < 0 || x >= 7 || y >= height end) &&
      Enum.all?(rock, fn {x, y} -> y < 0 || Enum.at(stack, y) |> Enum.at(x) == :clear end)
  end

  defp place_rock(rock, height, stack) do
    get_y = &elem(&1, 1)
    min_y = Enum.map(rock, get_y) |> Enum.min()
    min_y_or_zero = min(min_y, 0)
    new_rows = List.duplicate(List.duplicate(:clear, 7), -1 * min_y_or_zero)

    new_stack =
      Enum.reduce(rock, new_rows ++ stack, fn {x, y}, st ->
        List.update_at(st, y - min_y_or_zero, fn list -> List.replace_at(list, x, :blocked) end)
      end)

    {height - min_y_or_zero, new_stack}
  end

  @pixels %{clear: '.', blocked: '#'}
  def print_stack(stack) do
    Enum.map(stack, fn line -> IO.puts(:stderr, '|' ++ Enum.map(line, &@pixels[&1]) ++ '|') end)
    IO.puts(:stderr, "+-------+")
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day17, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day17.main()

#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/12

defmodule Day12Deque do
  @moduledoc """
  WIP solution to see if implementing an ArrayDeque is faster than using a cons
  list as a queue for breadth-first search.
  TODO: Also try this with Erlang's :array module.
  """

  defmodule ArrayDeque do
    defstruct queue: {}, first: 0, last: -1

    def new(list) do
      queue = List.to_tuple(list)
      struct!(ArrayDeque, queue: queue, first: 0, last: tuple_size(queue))
    end

    def empty?(%ArrayDeque{first: first, last: last}), do: first <= last

    def shift(%ArrayDeque{first: first, last: last}) when first > last, do: raise("Empty dequeu")

    def shift(%ArrayDeque{queue: queue, first: first} = deque) do
      {elem(queue, first), struct!(deque, first: first + 1)}
    end

    def push(%ArrayDeque{first: first, last: last}, value) when first > last do
      struct!(ArrayDeque, queue: {value}, first: 0, last: 0)
    end

    def push(%ArrayDeque{queue: queue, first: first, last: last}, value)
        when tuple_size(queue) >= last do
      new =
        Enum.reduce(first..last, Tuple.duplicate(nil, min((last - first) * 2, 1)), fn i, acc ->
          put_elem(acc, i, queue[i])
        end)

      next = last - first + 1
      new = put_elem(new, next, value)
      struct!(ArrayDeque, queue: new, first: 0, last: next)
    end

    def push(%ArrayDeque{queue: queue, last: last} = deque, value) do
      struct!(deque, queue: put_elem(queue, last + 1, value), last: last + 1)
    end
  end

  @doc "Count the steps in the shortest path from start to end."
  def part1(input) do
    {grid, start, stop} = parse(input)
    # bfs([{start, 0}], grid, stop, MapSet.new([start]))
    bfs(ArrayDeque.new([{start, 0}]), grid, stop, MapSet.new([start]))
  end

  @doc "Find the shorted path to end starting at any `a` position."
  def part2(input) do
    {grid, _start, stop} = parse(input)

    Map.filter(grid, fn {_, height} -> height == ?a end)
    |> Map.keys()
    # |> Enum.map(fn coord -> bfs([{coord, 0}], grid, stop, MapSet.new([coord])) end)
    |> Enum.map(fn coord -> bfs(ArrayDeque.new()[{coord, 0}], grid, stop, MapSet.new([coord])) end)
    |> Enum.reject(&(&1 == :not_found))
    |> Enum.min()
  end

  defp parse(input) do
    input
    |> Enum.with_index(1)
    |> Enum.reduce({%{}, 0, 0}, fn {line, row}, accout ->
      to_charlist(line)
      |> Enum.with_index(1)
      |> Enum.reduce(accout, fn {char, col}, {grid, start, stop} ->
        coord = {row, col}

        case char do
          ?S -> {Map.put(grid, coord, ?a), coord, stop}
          ?E -> {Map.put(grid, coord, ?z), start, coord}
          _ -> {Map.put(grid, coord, char), start, stop}
        end
      end)
    end)
  end

  # defp bfs([], _grid, _target, _visited), do: :not_found

  # defp bfs([{coord, moves} | _tail], _grid, coord, _visited), do: moves

  # defp bfs([{coord, moves} | tail], grid, target, visited) do
  #   next =
  #     valid_moves(coord, grid)
  #     |> Enum.filter(&(!MapSet.member?(visited, &1)))
  #     |> Enum.map(&{&1, moves + 1})
  #
  #   queue = tail ++ next
  #   bfs(queue, grid, target, MapSet.union(visited, MapSet.new(next |> Enum.map(&elem(&1, 0)))))
  # end

  defp bfs(deque, grid, target, visited) do
    cond do
      ArrayDeque.empty?(deque) ->
        :not_found

      {{^target, moves}, _} = ArrayDeque.shift(deque) ->
        moves

      {{coord, moves}, deque} = ArrayDeque.shift(deque) ->
        with do
          next =
            valid_moves(coord, grid)
            |> Enum.filter(&(!MapSet.member?(visited, &1)))
            |> Enum.map(&{&1, moves + 1})

          dq = Enum.reduce(next, deque, &ArrayDeque.push(&2, &1))
          bfs(dq, grid, target, MapSet.union(visited, MapSet.new(next |> Enum.map(&elem(&1, 0)))))
        end
    end
  end

  defp valid_moves({row, col}, grid) do
    cur_height = grid[{row, col}]

    [{-1, 0}, {1, 0}, {0, -1}, {0, 1}]
    |> Enum.map(fn {x, y} -> {row + x, col + y} end)
    |> Enum.filter(&Map.has_key?(grid, &1))
    |> Enum.filter(fn coord -> grid[coord] - cur_height <= 1 end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day12, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day12.main()

#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/20

defmodule Day20 do
  @moduledoc """
  Input is lines of integers (positive and negative, plus exactly one 0)
  representing a circular cycle.  To "mix" a file of integers, each is moved
  forward or backwards in the circle a number of places equal to the number.
  Numbers are moved in the order they appear in the file, not in their current
  circular order.

  The problem description says

  > move each number forward or backward in the file a number of positions equal
  > to the value of the number being moved

  This suggested to me, and many other coders, that "numbers" and "positions"
  are separable, e.g., the example contains 7 position slots and you find the
  new slot, put the number there, and slide all the other values up or down to
  fill the space.  However, the Advent of Code server interprets that
  instruction as the number stepping forward or backward one neighbor at a time.
  The difference is that an input number equal to the size of the list will, in
  the first interpretation, end up back its original position but in the second
  interpretation will be in front of the neighbor that's currently in front of
  it.  Suppose Alice, Mad Hatter, Dormouse, and March Hare are having a tea
  party, seated around a table in that order.  Alice receives an instruction to
  move 5 places forward.  In the first interpretation she would walk around the
  table counting chairs: Mad Hatter's chair is 1, Dormouse's chair is 2, March
  Hare's chair is 3, Alice gets back to her own chair at 4, and then on 5 takes
  Mad Hatter's chair; Mad Hatter moves one step back to Alice's old chair.
  In the second interpretation, Alice pulls her chair out from the table and
  carries it while she circles the table.  On 1 she passes Mad Hatter, on 2 she
  passes Dormouse, on 3 she passes March Hare, then on 4 she is back to Mad
  Hatter (not her old empty spot), and thus on 5 she inserts herself between
  Dormouse and March Hare.
  """

  defmodule Node do
    defstruct id: 0, prev: 0, next: 0

    def find(node, 0, _nodes), do: node
    def find(node, steps, nodes) when steps < 0, do: find(nodes[node.prev], steps + 1, nodes)
    def find(node, steps, nodes) when steps > 0, do: find(nodes[node.next], steps - 1, nodes)

    def insert(node, left_id, right_id, nodes) do
      Map.merge(nodes, %{
        node.id => struct!(node, prev: left_id, next: right_id),
        left_id => struct!(nodes[left_id], next: node.id),
        right_id => struct!(nodes[right_id], prev: node.id)
      })
    end

    def remove(node, nodes) do
      left = nodes[node.prev]
      right = nodes[node.next]

      Map.delete(nodes, node.id)
      |> Map.merge(%{
        left.id => struct!(left, next: right.id),
        right.id => struct!(right, prev: left.id)
      })
    end
  end

  @doc "Mix the file once, add the 1000th, 2000th, and 3000th numbers after 0."
  def part1(input) do
    {order, values, nodes} = parse_input(Enum.map(input, &String.to_integer/1))
    find_result(values, move_all(order, values, nodes))
  end

  @doc "Multiply each number by a large constant, mix the file ten times."
  @multiplier 811_589_153
  def part2(input) do
    {order, vals, nodes} = parse_input(Enum.map(input, &(String.to_integer(&1) * @multiplier)))
    find_result(vals, Enum.reduce(1..10, nodes, fn _, nodes -> move_all(order, vals, nodes) end))
  end

  defp find_result(values, nodes) do
    [{zero_id, 0}] = Enum.filter(values, fn {_, val} -> val === 0 end)
    one = Node.find(nodes[zero_id], 1000, nodes)
    two = Node.find(nodes[one.id], 1000, nodes)
    three = Node.find(nodes[two.id], 1000, nodes)
    Enum.map([one, two, three], &values[&1.id]) |> Enum.sum()
  end

  defp move_all(order, values, nodes) do
    cycle = Map.size(nodes) - 1
    Enum.reduce(order, nodes, fn id, nodes -> move(id, rem(values[id], cycle), nodes) end)
  end

  defp move(_, 0, nodes), do: nodes

  defp move(id, steps, nodes) do
    node = nodes[id]
    nodes = Node.remove(node, nodes)
    dest = Node.find(node, steps, nodes)

    if steps < 0,
      do: Node.insert(node, dest.prev, dest.id, nodes),
      else: Node.insert(node, dest.id, dest.next, nodes)
  end

  defp parse_input(numbers) do
    first_index = 100_000
    last_index = first_index + Enum.count(numbers) - 1

    # {order, values, nodes}
    numbers
    |> Enum.with_index(first_index)
    |> Enum.reduce({[], %{}, %{}}, fn
      {val, ^first_index}, {[], %{}, %{}} ->
        {[first_index], %{first_index => val},
         %{first_index => %Node{id: first_index, prev: last_index, next: first_index + 1}}}

      {val, ^last_index}, {order, values, nodes} ->
        {order ++ [last_index], Map.put(values, last_index, val),
         Map.put(nodes, last_index, %Node{
           id: last_index,
           prev: last_index - 1,
           next: first_index
         })}

      {val, id}, {order, values, nodes} ->
        {order ++ [id], Map.put(values, id, val),
         Map.put(nodes, id, %Node{id: id, prev: id - 1, next: id + 1})}
    end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day20, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day20.main()

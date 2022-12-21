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
    defstruct value: nil, prev: nil, next: nil

    def new(value, prev, next) do
      {:ok, pid} = Agent.start_link(fn -> %Node{value: value, prev: prev, next: next} end)
      pid
    end

    def get(agent), do: Agent.get(agent, &Function.identity/1)

    def find(agent, 0), do: agent
    def find(agent, steps) when steps < 0, do: find(get(agent).prev, steps + 1)
    def find(agent, steps) when steps > 0, do: find(get(agent).next, steps - 1)

    def find_value(agent, val) do
      node = get(agent)
      if node.value === val, do: agent, else: find_value(node.next, val)
    end

    def set_prev(agent, prev), do: Agent.update(agent, fn node -> struct!(node, prev: prev) end)

    def set_next(agent, next), do: Agent.update(agent, fn node -> struct!(node, next: next) end)

    def insert(agent, left, right) do
      node = Node.get(agent)
      set_next(left, agent)
      set_prev(right, agent)
      set_next(agent, right)
      set_prev(agent, left)
      :ok
    end
  end

  @doc "Mix the file once, add the 1000th, 2000th, and 3000th numbers after 0."
  def part1(input) do
    {agents, first, size} = build_list(input |> Enum.map(&String.to_integer/1))
    find_result(move_agents(agents, first, size))
  end

  @doc "Multiply each number by a large constant, mix the file ten times."
  @multiplier 811_589_153
  def part2(input) do
    {agents, first, size} = build_list(input |> Enum.map(&(String.to_integer(&1) * @multiplier)))
    find_result(Enum.reduce(1..10, first, fn _, first -> move_agents(agents, first, size) end))
  end

  defp build_list(numbers) do
    {agents, {first, last, size}} =
      Enum.map_reduce(numbers, {nil, nil, 0}, fn
        val, {nil, nil, 0} ->
          agent = Node.new(val, nil, nil)
          {agent, {agent, agent, 1}}

        val, {first, last, count} ->
          agent = Node.new(val, last, nil)
          Node.set_next(last, agent)
          {agent, {first, agent, count + 1}}
      end)

    Node.set_prev(first, last)
    Node.set_next(last, first)
    {agents, first, size}
  end

  defp move_agents(agents, first, size) do
    for a <- agents do
      before = Node.get(a)
      steps = rem(before.value, size - 1)

      if steps != 0 do
        Node.set_next(before.prev, before.next)
        Node.set_prev(before.next, before.prev)
        found = Node.find(a, steps)
        found_node = Node.get(found)
        {left, right} = if steps < 0, do: {found_node.prev, found}, else: {found, found_node.next}
        Node.insert(a, left, right)
      end
    end

    first
  end

  defp find_result(first) do
    zero = Node.find_value(first, 0)
    one = Node.find(zero, 1000)
    two = Node.find(one, 1000)
    three = Node.find(two, 1000)
    Enum.map([one, two, three], fn agent -> Node.get(agent).value end) |> Enum.sum()
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day20, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day20.main()

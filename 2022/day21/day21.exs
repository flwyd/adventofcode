#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/21

defmodule Day21 do
  @moduledoc """
  Input is a graph of arithmetic nodes, with a four-character name and either
  a binary operation between two other names or a positive integer value.
  Calculation starts at the node named "root".  There is also a "humn" node
  which is relevant in part2.
  """
  import MapSet, only: [member?: 2]

  defmodule Op do
    defstruct name: "", left: "", right: "", value: 0, operation: ?!

    def get(op, :left), do: op.left
    def get(op, :right), do: op.right

    def get_value(name, ctx), do: evaluate(ctx[name], ctx)

    def evaluate(%Op{operation: ?!, value: val}, _ctx), do: val
    def evaluate(%Op{operation: ?+} = op, ctx), do: binary_op(op, &+/2, ctx)
    def evaluate(%Op{operation: ?-} = op, ctx), do: binary_op(op, &-/2, ctx)
    def evaluate(%Op{operation: ?*} = op, ctx), do: binary_op(op, &*/2, ctx)
    def evaluate(%Op{operation: ?/} = op, ctx), do: binary_op(op, &div/2, ctx)

    defp binary_op(%Op{left: left, right: right}, func, ctx),
      do: func.(get_value(left, ctx), get_value(right, ctx))
  end

  @doc "Evaluate the graph starting from root."
  def part1(input) do
    ctx = input |> Enum.map(&parse_line/1) |> Map.new(fn %Op{name: n} = op -> {n, op} end)
    Op.get_value("root", ctx)
  end

  @doc "root is now an equality operation; find the humn value to make it so."
  def part2(input) do
    ctx = input |> Enum.map(&parse_line/1) |> Map.new(fn %Op{name: n} = op -> {n, op} end)
    root = ctx["root"]
    {true, has_humn} = find_humn(root, ctx, MapSet.new())

    {first, second} =
      if member?(has_humn, root.left), do: {root.right, root.left}, else: {root.left, root.right}

    {false, true} = {member?(has_humn, first), member?(has_humn, second)}
    target = Op.get_value(first, ctx)
    determine_humn(ctx[second], target, ctx, has_humn)
  end

  defp determine_humn(%Op{name: "humn"}, target, _ctx, _h), do: target

  defp determine_humn(op, target, ctx, has_humn) do
    {has, lacks} = if member?(has_humn, op.left), do: {:left, :right}, else: {:right, :left}
    {false, true} = {member?(has_humn, Op.get(op, lacks)), member?(has_humn, Op.get(op, has))}
    val = Op.evaluate(ctx[Op.get(op, lacks)], ctx)

    new_target =
      case {lacks, op.operation} do
        {_, ?+} -> target - val
        {:left, ?-} -> val - target
        {:right, ?-} -> target + val
        {_, ?*} -> div(target, val)
        {:left, ?/} -> div(val, target)
        {:right, ?/} -> target * val
      end

    determine_humn(ctx[Op.get(op, has)], new_target, ctx, has_humn)
  end

  def find_humn(%Op{name: "humn"}, _ctx, acc), do: {true, MapSet.put(acc, "humn")}
  def find_humn(%Op{left: "", right: ""}, _ctx, acc), do: {false, acc}

  def find_humn(%Op{name: name, left: l, right: r}, ctx, acc) do
    case find_humn(ctx[l], ctx, acc) do
      {true, acc} ->
        {true, MapSet.put(acc, name)}

      {false, acc} ->
        case find_humn(ctx[r], ctx, acc) do
          {true, acc} -> {true, MapSet.put(acc, name)}
          {false, acc} -> {false, acc}
        end
    end
  end

  defp parse_line(
         <<name::binary-size(4), ": ", a::binary-size(4), " ", op, " ", b::binary-size(4)>>
       ),
       do: %Op{name: name, operation: op, left: a, right: b}

  defp parse_line(<<name::binary-size(4), ": ", rest::binary>>),
    do: %Op{name: name, value: String.to_integer(rest)}

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day21, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day21.main()

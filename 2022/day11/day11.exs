#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/11

defmodule Day11 do
  @moduledoc """
  Input is multi-line monkey definitions, separated by blank lines.  Monkeys are
  numbered sequentially from 0 and have a list of items with current worry
  levels.  They have an addition or multiplication operator to transform the
  wory level to a new value, then pass it to another monkey depending on whether
  the worry level is divisible by the current monkey's divisor.  Each round,
  each monkey passes all of their items in sequence.  Solution is the product of
  the number of times an item was passed by the two most active monkeys.
  """
  import String, only: [to_integer: 1]

  defmodule Monkey do
    defstruct num: -1, items: [], op: &Function.identity/1, divisor: 0, yes: -1, no: -1, times: 0

    def parse(lines) do
      [
        <<"Monkey ", mnum, ":">>,
        "  Starting items: " <> starts,
        "  Operation: new = " <> oper,
        "  Test: divisible by " <> divisor,
        "    If true: throw to monkey " <> yesnum,
        "    If false: throw to monkey " <> nonum
      ] = lines

      op =
        case oper do
          "old + old" -> &(&1 + &1)
          "old * old" -> &(&1 * &1)
          "old + " <> arg -> with x = to_integer(arg), do: &(&1 + x)
          "old * " <> arg -> with x = to_integer(arg), do: &(&1 * x)
        end

      %Monkey{
        num: mnum - ?0,
        items: Enum.map(String.split(starts, ", "), &to_integer/1),
        op: op,
        divisor: to_integer(divisor),
        yes: to_integer(yesnum),
        no: to_integer(nonum)
      }
    end

    def parse_several(input) do
      chunk_fun = fn x, acc -> if x == "", do: {:cont, acc, []}, else: {:cont, acc ++ [x]} end
      acc_fun = fn acc -> if Enum.empty?(acc), do: {:cont, acc}, else: {:cont, acc, acc} end

      input
      |> Enum.chunk_while([], chunk_fun, acc_fun)
      |> Enum.map(&parse/1)
      |> Enum.with_index()
      |> Enum.map(fn {m, i} -> if m.num != i, do: raise("Monkey #{m.num} ≠ #{i}"), else: m end)
      |> List.to_tuple()
    end
  end

  @doc "20 rounds, each item's worry level is int-divided by 3 when passed."
  def part1(input), do: solve(Monkey.parse_several(input), 20, &div(&1, 3))

  @doc "10000 rounds, no worry division (but mod by the least common multiple)."
  def part2(input) do
    monkeys = Monkey.parse_several(input)
    lcm = monkeys |> Tuple.to_list() |> Enum.map(& &1.divisor) |> Enum.product()
    solve(monkeys, 10_000, &rem(&1, lcm))
  end

  defp solve(monkeys, rounds, adjust_worry_fun) do
    Enum.reduce(1..rounds, monkeys, fn _, ms -> play_round(ms, adjust_worry_fun) end)
    |> Tuple.to_list()
    |> Enum.map(& &1.times)
    |> Enum.sort(:desc)
    |> Enum.take(2)
    |> Enum.product()
  end

  def play_round(monkeys, worry_fun) do
    Enum.reduce(0..(tuple_size(monkeys) - 1), monkeys, &play_turn(&1, &2, worry_fun))
  end

  def play_turn(who, monkeys, worry_fun) do
    Enum.reduce(elem(monkeys, who).items, monkeys, fn item, acc ->
      m = elem(acc, who)
      level = worry_fun.(m.op.(item))
      next = if rem(level, m.divisor) == 0, do: m.yes, else: m.no
      next_m = elem(acc, next)

      put_elem(
        put_elem(acc, next, struct!(next_m, items: next_m.items ++ [level])),
        who,
        struct!(m, times: m.times + 1, items: tl(m.items))
      )
    end)
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day11, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day11.main()

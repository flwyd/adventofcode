#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/7

defmodule Day7 do
  @moduledoc """
  Input is a series of `$ cd` and `$ ls` commands or directories/files shown by
  the preceding ls command.  `$ cd /` goes to the root dir, `$ cd ..` goes up
  one dir, and `$ cd x` goes down into directory x.  `ls` output is either
  `dir x` or `12345 x`, indicating a file's size.  Total size of a directory is
  the sum of file sizes below it.
  """

  @doc "Return the sum of total sizes where the dir has total size <= 10000"
  def part1(input) do
    parse_files(input) |> total_sizes_matching(&(&1 <= 100_000)) |> Enum.sum()
  end

  @doc """
  Return the total size of the smallest directory that can be deleted to get
  the total size of the root directory under 70000000.
  """
  def part2(input) do
    files = parse_files(input)
    root_size = total_size(files, "/")
    need = 30_000_000 - (70_000_000 - root_size)
    total_sizes_matching(files, &(&1 >= need)) |> Enum.min()
  end

  defp total_sizes_matching(files, predicate?) do
    files
    |> Enum.filter(fn {_, size} -> size == 0 end)
    |> Enum.map(fn {name, _} -> total_size(files, name <> "/") end)
    |> Enum.filter(predicate?)
  end

  defp total_size(files, prefix) do
    files
    |> Map.filter(fn {name, _} -> String.starts_with?(name, prefix) end)
    |> Map.values()
    |> Enum.sum()
  end

  defmodule FileSys, do: defstruct(pwd: [], files: %{"/" => 0})

  defp parse_files(input),
    do: input |> Enum.reduce(%FileSys{}, &process_line/2) |> Map.get(:files)

  defp process_line(<<"$ cd /">>, %FileSys{} = sys), do: Map.put(sys, :pwd, [""])

  defp process_line(<<"$ cd ..">>, %FileSys{pwd: pwd} = sys),
    do: Map.put(sys, :pwd, Enum.drop(pwd, -1))

  defp process_line(<<"$ cd ", dir::binary>>, %FileSys{pwd: pwd} = sys),
    do: Map.put(sys, :pwd, Enum.concat(pwd, [dir]))

  defp process_line(<<"$ ls">>, %FileSys{} = sys), do: sys

  defp process_line(<<"dir ", dir::binary>>, %FileSys{pwd: pwd} = sys) do
    path = Enum.join(Enum.concat(pwd, [dir]), "/")
    Map.update!(sys, :files, &Map.put(&1, path, 0))
  end

  defp process_line(line, %FileSys{pwd: pwd} = sys) do
    [size, name] = String.split(line, " ")
    path = Enum.join(Enum.concat(pwd, [name]), "/")
    Map.update!(sys, :files, &Map.put(&1, path, String.to_integer(size)))
  end

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day7, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day7.main()

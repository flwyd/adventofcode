#!/usr/bin/env elixir
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/10

defmodule Day10 do
  @moduledoc """
  Input is "noop" or "addx number" lines.  noop instructions take one cycle,
  addx instructions take two cycles.  addx adds or subtracts to the x
  register which starts at 1.
  """

  defmodule Raster do
    @moduledoc """
    Raster contains rows of boolean values and implements `to_string`.
    To ensure output starts at the beginning of a line, prefix rows with `[]`.

    ## Examples:
    # Make output stand out with magenta squares
    iex> %Day10.Raster{rows: rows} = Day10.part2(Runner.read_lines(actualtxt))
    iex> IO.puts(Day10.Raster.new(tl(rows),
      {IO.ANSI.format([:magenta_background, :magenta, ?#]), ?\s}))
    """
    defstruct rows: [], on: ?#, off: ?.

    def new(rows, {on, off} \\ {?#, ?.}), do: %Raster{rows: rows, on: on, off: off}
  end

  defimpl String.Chars, for: Raster do
    def to_string(%Raster{rows: rows, on: on, off: off}) do
      rows |> Enum.map(fn row -> Enum.map(row, &if(&1, do: on, else: off)) end) |> Enum.join("\n")
    end
  end

  @doc "Sum the cycle times x for every 40th cycle starting at 20."
  def part1(input) do
    xvals = input |> Enum.map(&parse_line/1) |> compute_xvalues()
    [20, 60, 100, 140, 180, 220] |> Enum.map(fn i -> i * xvalue(i, xvals) end) |> Enum.sum()
  end

  @doc """
  X values are the middle of a 3-pixel sprite on a 6x40 scanning CRT.
  At each cycle, if the sprite overlaps the (0-based) pixel position, print a
  pixel.  Then identify the capital latin letters on the display.
  """
  def part2(input) do
    xvals = input |> Enum.map(&parse_line/1) |> compute_xvalues()

    ([[]] ++
       for row <- 0..5 do
         Enum.map(0..39, fn col ->
           step = row * 40 + col + 1
           abs(xvalue(step, xvals) - col) <= 1
         end)
       end)
    |> Raster.new()
  end

  defp xvalue(step, xvals) do
    xvals[Enum.filter(step..(step - 1), &Map.has_key?(xvals, &1)) |> List.first()]
  end

  defp compute_xvalues(instructions) do
    {_steps, _final_x, xvals} =
      Enum.reduce(instructions, {1, 1, %{}}, fn {cycles, delta}, {step, x, xvals} ->
        {step + cycles, x + delta, Map.put(xvals, step, x)}
      end)

    xvals
  end

  defp parse_line("noop"), do: {1, 0}
  defp parse_line("addx " <> amount), do: {2, String.to_integer(amount)}

  def main() do
    unless function_exported?(Runner, :main, 1), do: Code.compile_file("../runner.ex", __DIR__)
    success = Runner.main(Day10, System.argv())
    exit({:shutdown, if(success, do: 0, else: 1)})
  end
end

if Path.absname(:escript.script_name()) == Path.absname(__ENV__.file), do: Day10.main()

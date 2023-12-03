#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 3
[Read the puzzle](https://adventofcode.com/2023/day/3)

Input is a grid with dots as empty space, punctuation as engine parts, and multi-digit numbers.
Part 1 sums all the numbers adjacent (including diagonal) to a part.
Part 2 is only concerned with gears, marked by asterisks.  The gear ratio is the product of
two numbers adjacent to a gear; gears with only one adjacent number have no gear ratio.
The answer is the sum of the gear ratios.
"""
module Day3

function part1(lines)
  input = parseinput(lines)
  grid = [input[i][j] for i in 1:length(input), j in 1:length(input[1])]
  rows, cols = size(grid)
  partnums::Vector{Int} = []
  num = []
  sawsymbol = false
  notparts = zeros(Bool, axes(grid))
  for i in 1:rows, j in 1:cols
    c = grid[i, j]
    if c != '.' && !isdigit(c)
      for row in max(1, i - 1):min(rows, i + 1), col in max(1, j - 1):min(cols, j + 1)
        notparts[row, col] = true
      end
    end
  end
  for i in 1:rows, j in 1:cols
    c = grid[i, j]
    if isdigit(c)
      if isempty(num)
        sawsymbol = false
      end
      push!(num, c)
      if notparts[i, j]
        sawsymbol = true
      end
    end
    if !isdigit(c) || j == cols
      if sawsymbol && !isempty(num)
        push!(partnums, parse(Int, join(num, "")))
      end
      num = []
    end
  end
  sum(partnums)
end

function part2(lines)
  input = parseinput(lines)
  grid = [input[i][j] for i in 1:length(input), j in 1:length(input[1])]
  rows, cols = size(grid)
  total = 0
  for i in 1:rows, j in 1:cols
    if grid[i, j] == '*'
      ranges = Set()
      for row in max(1, i - 1):min(rows, i + 1), col in max(1, j - 1):min(cols, j + 1)
        if isdigit(grid[row, col])
          push!(ranges, digitspan(grid, row, col))
        end
      end
      length(ranges) > 2 && error("$i,$j gear has $ranges ranges")
      if length(ranges) == 2
        total += prod([parse(Int, join(grid[row, range], "")) for (row, range) in ranges])
      end
    end
  end
  total
end

function parseinput(lines)
  map(lines) do line
    line
  end
end

function digitspan(grid, row, col)
  !isdigit(grid[row, col]) && error("$row,$col is $(grid[row, col])")
  first = something(findlast(!isdigit, grid[row, 1:col]), 0) + 1
  last = something(findnext(!isdigit, grid[row, 1:end], col), size(grid)[2] + 1) - 1
  (row, first:last)
end

include("../Runner.jl")
@run_if_main
end

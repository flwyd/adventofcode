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
  grid = parseinput(lines)
  parts = [i for i in CartesianIndices(grid) if grid[i] != '.' && !isdigit(grid[i])]
  neighbors = unique(reduce(vcat, numberneighbors(grid, p) for p in parts))
  sum(readnum(grid, n) for n in neighbors)
end

function part2(lines)
  grid = parseinput(lines)
  gears = [i for i in CartesianIndices(grid) if grid[i] == '*']
  neighborpairs = [numberneighbors(grid, g) for g in gears] |> filter(n -> length(n) == 2)
  sum(prod([readnum(grid, n) for n in p]) for p in neighborpairs)
end

parseinput(lines) = reduce(hcat, collect(line) for line in lines)

function neighborhood(grid, point)
  # See https://julialang.org/blog/2016/02/iteration/ for multi-dimensional iteration
  indices = CartesianIndices(grid)
  ifirst, ilast = first(indices), last(indices)
  one = oneunit(ifirst)
  max(ifirst, point - one):min(ilast, point + one)
end

function digitrun(grid, point)
  col = point[2]
  start = stop = point[1]
  firstrow = firstindex(grid, 1)
  lastrow = lastindex(grid, 1)
  while start >= firstrow
    !isdigit(grid[start, col]) && break
    start -= 1
  end
  while stop <= lastrow
    !isdigit(grid[stop, col]) && break
    stop += 1
  end
  # start is now 1 before first digit and stop is 1 after last digit
  CartesianIndex(start + 1, col):CartesianIndex(stop - 1, col)
end

function numberneighbors(grid, point)
  neighbors = neighborhood(grid, point)
  digitneighbors = [n for n in neighbors if isdigit(grid[n])]
  unique([digitrun(grid, n) for n in digitneighbors])
end

readnum(grid, range) = parse(Int, join(grid[range], ""))

include("../Runner.jl")
@run_if_main
end

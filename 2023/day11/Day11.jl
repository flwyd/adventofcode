#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 11
[Read the puzzle](https://adventofcode.com/2023/day/11)

Input is a grid of characters: `#` represents a galaxy, `.` represents space.  Compute the sum of
Manhattan distances between each pair of galaxies.  In part one, each empty row or column is
actually two wide; in part two each empty row or column is one million wide.

"""
module Day11

part1(lines) = solve(lines, 2)

part2(lines) = solve(lines, 1_000_000)

function solve(lines, factor)
  grid, galaxies, emptyrows, emptycols = parseinput(lines)
  map(enumerate(galaxies)) do (i, g)
    [dist(g, x, emptyrows, emptycols, factor) for x in galaxies[i+1:end]]
  end |> Iterators.flatten |> sum
end

function dist(a, b, emptyrows, emptycols, factor)
  arow, acol = Tuple(a)
  brow, bcol = Tuple(b)
  minrow, maxrow = minmax(arow, brow)
  mincol, maxcol = minmax(acol, bcol)
  height = maxrow - minrow + (factor-1) * length((minrow:maxrow) ∩ emptyrows)
  width = maxcol - mincol + (factor-1) * length((mincol:maxcol) ∩ emptycols)
  width + height
end

function parseinput(lines)
  grid = reduce(hcat, [collect(line) for line in lines])
  galaxies = findall(==('#'), grid)
  emptyrows = findall(x -> all(==('.'), x), eachrow(grid))
  emptycols = findall(x -> all(==('.'), x), eachcol(grid))
  grid, galaxies, emptyrows, emptycols
end

include("../Runner.jl")
@run_if_main
end

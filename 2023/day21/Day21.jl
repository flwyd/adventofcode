#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 21
[Read the puzzle](https://adventofcode.com/2023/day/21)

Input is a grid of walls `#`, open `.`, and start `S`.  Output is the number of possible positions
after N steps.  In part 1, steps are 6 in the example and 64 for actual.  In part 2, the grid
repeats infinitely and steps is 26501365.
"""
module Day21

function part1(lines)
  grid = parseinput(lines)
  start = findfirst(==('S'), grid)
  numrounds = size(grid, 1) < 20 ? 6 : 64
  naivecount(grid, start, numrounds)
end

function part2(lines)
  grid = parseinput(lines)
  if grid[2, size(grid, 2) ÷ 2 + 1] == '#'
    # AoC example doesn't have the vertical/horizontal "highways"
    start = size(grid, 1) * 5 + size(grid, 1) ÷ 2 + 1
    return naivecount(repeat(grid, outer=[11, 11]), CartesianIndex(start, start), 50)
  end
  # 26501365 for actual answer, scale by size of example2 which is adapted from AoC example
  magicnumber = 202300 * size(grid, 1) + size(grid, 1) ÷ 2
  keys = keysizes(grid)
  keysolve(grid, keys, magicnumber)
end

parseinput(lines) = reduce(hcat, collect.(lines))

const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(+1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, +1)
const NEIGHBORS = (UP, DOWN, LEFT, RIGHT)

neighbors(grid, i) = filter(n -> checkbounds(Bool, grid, n), map(x -> i + x, NEIGHBORS))

function naivecount(grid, start, numrounds)
  rounds = zeros(Bool, (size(grid)..., numrounds + 1))
  rounds[start, 1] = true
  for round in 1:numrounds, i in eachindex(IndexCartesian(), grid)
    if grid[i] != '#'
      for x in neighbors(grid, i)
        if rounds[x, round]
          rounds[i, round + 1] = true
        end
      end
    end
  end
  count(rounds[:, :, numrounds + 1])
end

function keysizes(singlegrid)
  height = size(singlegrid, 1)
  extra = 2
  bigsize = extra * 2 + 1
  grid = repeat(singlegrid, outer=[bigsize, bigsize])
  start = CartesianIndex(Tuple(x ÷ 2 + 1 for x in size(grid))) # dead center
  open = findall(!=('#'), grid)
  neighs = [c == '#' ? [] : neighbors(grid, i) for (i, c) in pairs(IndexCartesian(), grid)]
  numrounds = height * extra + height ÷ 2
  # TODO rather than taking numrounds steps, compute distance from start to each point and set count
  # based on number of odds
  rounds = zeros(Bool, (size(grid)..., numrounds + 1))
  rounds[start, 1] = true
  for round in 1:numrounds, i in open
    rounds[i, round + 1] = any(n -> rounds[n, round], neighs[i])
  end
  # return a 5x5 matrix with occupied counts after numrounds for each "copy" of singlegrid
  f(rows, cols) = count(rounds[rows, cols, numrounds + 1])
  reshape([f((i * height + 1):((1 + i) * height), (j * height + 1):((1 + j) * height))
           for i in (1:bigsize) .- 1 for j in (1:bigsize) .- 1],
    (5, 5))
end

function keysolve(grid, keymat, rounds)
  cells = (rounds - size(grid, 1) ÷ 2) ÷ size(grid, 1)
  odd = keymat[3, 3]
  even = keymat[2, 3]
  total = 0
  for c in (-cells):cells
    evens = max(cells - abs(c), 0)
    odds = max(cells - abs(c) - 1, 0)
    total += evens * even + odds * odd
    if c < 0
      total += keymat[1, 2] + keymat[1, 4]
      if c == -cells
        total += keymat[1, 3]
      else
        total += keymat[2, 2] + keymat[2, 4]
      end
    elseif c == 0
      total += keymat[3, 1] + keymat[3, 5]
    elseif c > 0
      total += keymat[5, 2] + keymat[5, 4]
      if c == cells
        total += keymat[5, 3]
      else
        total += keymat[4, 2] + keymat[4, 4]
      end
    end
  end
  total
end

include("../Runner.jl")
@run_if_main
end

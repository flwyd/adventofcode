#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 14
[Read the puzzle](https://adventofcode.com/2023/day/14)

Input is a grid where `O` are round rocks that roll when the grid is tilted and `#` are square
rocks that don't move.  The load is the sum of distances from the south edge of each `O` rock.
Part 1 is the load if you tilt north once.  Part 2 is the load if you shift [nort, west, south,
east] one billion times (or just find a cycle).
"""
module Day14

function part1(lines)
  input = parseinput(lines)
  map(row -> northweight(input, row), 1:size(input, 1)) |> sum
end

function part2(lines)
  input = parseinput(lines)
  finalgrid = cycleuntilstable(input)
  score(finalgrid)
end

parseinput(lines) = reduce(hcat, collect.(lines))

function northweight(grid, row)
  south = size(grid, 2) + 1
  lastrock = 0
  weight = 0
  for (i, c) in enumerate(grid[row, :])
    if c == 'O'
      weight += south - (lastrock + 1)
      lastrock += 1
    elseif c == '#'
      lastrock = i
    end
  end
  weight
end

function score(grid)
  map(axes(grid, 2)) do i
    count(==('O'), grid[:,i]) * (size(grid, 2) + 1 - i)
  end |> sum
end

function cyclerocks(grid)
  lastrock = 0
  north = (1, 1, first(axes(grid)))
  west = (2, 1, last(axes(grid)))
  south = (1, -1, reverse(first(axes(grid))))
  east = (2, -1, reverse(last(axes(grid))))
  newgrid = copy(grid)
  for (dim, sign, indexes) in (north, west, south, east)
    for i in indexes
      lastrock = first(indexes) - sign
      inner = selectdim(newgrid, dim, i)
      iter = sign == 1 ? enumerate(inner) : Iterators.reverse(enumerate(inner))
      for (j, c) in iter
        if c == 'O'
          target = lastrock + sign
          coord = dim == 1 ? CartesianIndex(i, target) : CartesianIndex(target, i)
          curcoord = dim == 1 ? CartesianIndex(i, j) : CartesianIndex(j, i)
          if coord != curcoord
            setindex!(newgrid, 'O', coord)
            setindex!(newgrid, '.', curcoord)
            lastrock = target
          else
            lastrock = j
          end
        elseif c == '#'
          lastrock = j
        end
      end
    end
  end
  newgrid
end

function cycleuntilstable(grid)
  cache = Dict(grid => 0)
  totaliters = 1_000_000_000
  remaining = totaliters
  for i in 1:totaliters
    grid = cyclerocks(grid)
    if grid in keys(cache)
      size = i - cache[grid]
      remaining = (totaliters - i) % size
      break
    end
    cache[grid] = i
  end
  for _ in 1:remaining
    grid = cyclerocks(grid)
  end
  grid
end

include("../Runner.jl")
@run_if_main
end

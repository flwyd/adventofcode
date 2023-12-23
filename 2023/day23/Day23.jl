#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 23
[Read the puzzle](https://adventofcode.com/2023/day/23)

Input is a grid of open spaces (`.`), walls (`#`), and downslopes (`<>^v`).  Start point is the
one open spot in the top row (one to the right of the edge) and destination is the one open spot
in the bottom row (one to the left of the edge).  Output is the longest path from start to
destination.  In part 1, when you're on a downslope you can only move in that direction.
In part 2, you can move in any free direction even when on a downslope.
"""
module Day23

function part1(lines)
  grid = parseinput(lines)
  start, target = CartesianIndex(1, 2), CartesianIndex(size(grid, 1), size(grid, 2) - 1)
  len, reached = longestpath(grid, start + DOWN, target, Set([start]), true)
  !reached && error("could not reach $target from $start")
  len
end

function part2(lines)
  grid = parseinput(lines)
  start, target = CartesianIndex(1, 2), CartesianIndex(size(grid, 1), size(grid, 2) - 1)
  longestpath2(grid, start, target)
end

function parseinput(lines)
  permutedims(reduce(hcat, collect.(lines)), (2, 1))
end

begin
  const LEFT = CartesianIndex(0, -1)
  const RIGHT = CartesianIndex(0, +1)
  const UP = CartesianIndex(-1, 0)
  const DOWN = CartesianIndex(+1, 0)
  const DIRS = (DOWN, RIGHT, UP, LEFT)
  const DOWNHILL = Dict('v' => DOWN, '>' => RIGHT, '^' => UP, '<' => LEFT)
end

function longestpath(grid, start, target, visited, downslopeonly)
  if start == target
    return 1, true
  end
  if !checkbounds(Bool, grid, start)
    return 0, false
  end
  cur = grid[start]
  if cur == '#'
    return 0, false
  end
  vis = visited ∪ (start,)
  dirs = if downslopeonly && haskey(DOWNHILL, cur)
    (DOWNHILL[cur],)
  else
    DIRS
  end
  lengths = Int[]
  for d in dirs
    next = start + d
    if next ∉ vis
      len, reached = longestpath(grid, next, target, vis, downslopeonly)
      if reached
        push!(lengths, 1+len)
      end
    end
  end
  isempty(lengths) ? (0, false) : (maximum(lengths), true)
end

function keypoints(grid)
  filter(x -> grid[x] != '#' && length(neighbors(grid, x)) > 2, eachindex(IndexCartesian(), grid))
end

function longestpath2(grid, start, target)
  keyp = vcat([start, target], keypoints(grid))
  nearby = Dict(x => Dict{CartesianIndex{2}, Int}() for x in keyp)
  for k in keyp
    for m in neighbors(grid, k)
      len = 1
      prev = k
      cur = m
      while cur ∉ keyp
        len += 1
        next = filter(x -> x != prev && x != k, neighbors(grid, cur))
        if length(next) != 1
          @show (k, m, cur, prev, next)
        end
        prev = cur
        cur = only(next)
      end
      nearby[k][cur] = len
    end
  end
  longest(nearby, start, target, CartesianIndex{2}[])
end

function longest(nearby, start, target, seen)
  if start == target
    return 0
  end
  lengths = Int[]
  seen = vcat(seen, start)
  for (k, v) in nearby[start]
    if k ∉ seen
      push!(lengths, v + longest(nearby, k, target, seen))
    end
  end
  return maximum(lengths; init=typemin(Int))
end

function neighbors(grid::Matrix{Char}, cur::CartesianIndex{2})
  filter(x -> checkbounds(Bool, grid, x) && grid[x] != '#', map(d -> cur + d, DIRS))
end

include("../Runner.jl")
@run_if_main
end

#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 17
[Read the puzzle](https://adventofcode.com/2023/day/17)

Input is a grid of digits representing the cost to move into a cell.  Turns to the left and right
are allowed, as is moving forward if you haven't already traveled too far.  Result is the minimum
cost to get from top left to bottom right.  Part 1's forward movement limit is 3.  Part 2 has a
minimum forward movement of 4 (no turns until you've moved forward 4) and a limit of 10.
"""
module Day17

function part1(lines)
  minimum(x -> x.cost, finalstates(moverules(1, 3), parseinput(lines)))
end

function part2(lines)
  # example2 requires moving at least 4 before stopping in the bottom right, but my input worked
  # without the >=4 check
  minimum(x -> x.cost, filter(s -> s.steps >= 4, finalstates(moverules(4, 10), parseinput(lines))))
end

parseinput(lines) = permutedims(reduce(hcat, parse.(Int, split(l, "")) for l in lines), (2, 1))

function finalstates(movefun, grid)
  states = similar(grid, Vector{State})
  for i in eachindex(grid)
    states[i] = []
  end
  start = CartesianIndex(1, 1)
  states[start] = [State(DOWN, 0, 0), State(RIGHT, 0, 0)]
  queue = [start]
  while !isempty(queue)
    cur = popfirst!(queue)
    for s in states[cur]
      for (pos, head, steps) in movefun(grid, cur, s.heading, s.steps)
        cost = s.cost + grid[pos]
        if any(x -> x.heading == head && x.steps == steps && x.cost <= cost, states[pos])
          continue
        end
        deleteat!(states[pos], findall(x -> x.heading == head && x.steps == steps && x.cost > cost, states[pos]))
        push!(states[pos], State(head, steps, cost))
        push!(queue, pos)
      end
    end
  end
  states[CartesianIndex(lastindex(grid, 1), lastindex(grid, 2))]
end

function moverules(min, max)
  function (grid, pos, heading, steps)
    left = (steps < min ? INVALID : pos + LEFT_TURN[heading], LEFT_TURN[heading], 1)
    right = (steps < min ? INVALID : pos + RIGHT_TURN[heading], RIGHT_TURN[heading], 1)
    forward = (steps < max ? pos + heading : INVALID, heading, steps + 1)
    filter(m -> first(m) ∈ keys(grid), (left, right, forward))
  end
end

struct State
  heading::CartesianIndex{2}
  steps::Int
  cost::Int
end

Base.hash(x::State, h::UInt) = hash(x.heading, hash(x.steps, hash(x.cost, h)))
Base.:(==)(a::State, b::State) = a.heading == b.heading && a.steps == b.steps && a.cost == b.cost
function Base.isequal(a::State, b::State)
  isequal(a.heading, b.heading) && isequal(a.steps, b.steps) && isequal(a.cost, b.cost)
end

const INVALID = CartesianIndex(0, 0)
const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, 1)
const LEFT_TURN = Dict(UP => LEFT, DOWN => RIGHT, LEFT => DOWN, RIGHT => UP)
const RIGHT_TURN = Dict(UP => RIGHT, DOWN => LEFT, LEFT => UP, RIGHT => DOWN)

include("../Runner.jl")
@run_if_main
end

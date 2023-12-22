#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 22
[Read the puzzle](https://adventofcode.com/2023/day/22)

Input is two `x,y,z` 3D coordinates describing a brick such that at least two of `xyz` are equal,
i.e. bricks are line segments.  Bricks fall until they're on top of at least one other brick, no
matter how ridiculous the physics.  In part 1, calculate the number of bricks which would _not_
cause other bricks to fall if they were removed in isolation (i.e. with replacement).  In part 2,
consider each brick in isolation and sum the number of bricks which would move if that brick were
removed from the stack.

It happens to be the case that the first point in each line of the input is ≤ the second point
in all three dimensions.
"""
module Day22

function part1(lines)
  bricks = fall(parseinput(lines))
  supports = findsupports(bricks)
  removable = Int[]
  for i in eachindex(bricks)
    resting = filter(o -> i ∈ o && length(o) == 1, supports)
    if isempty(resting)
      push!(removable, i)
    end
  end
  length(removable)
end

function part2(lines)
  bricks = fall(parseinput(lines))
  supports = findsupports(bricks)
  sum([chainsize(supports, i) for i in eachindex(bricks)])
end

struct Brick
  first::Tuple{Int, Int, Int}
  second::Tuple{Int, Int, Int}
end

squares(b::Brick, axis::Int) = min(b.first[axis], b.second[axis]):max(b.first[axis], b.second[axis])

topz(b::Brick) = b.second[3]
bottomz(b::Brick) = b.first[3]
overlapxy(a::Brick, b::Brick) = all(!isdisjoint(squares(a, i), squares(b, i)) for i in (1, 2))

function movez(b::Brick, bottom::Int)
  Brick((b.first[1], b.first[2], bottom),
    (b.second[1], b.second[2], bottom - 1 + length(squares(b, 3))))
end

function parseinput(lines)
  map(lines) do line
    first, second = split(line, "~")
    Brick(Tuple(parse.(Int, split(first, ","))), Tuple(parse.(Int, split(second, ","))))
  end
end

function fall(bricks::Vector{Brick})
  result = Brick[]
  for brick in sort(bricks; by=bottomz)
    landed = false
    for i in length(result):-1:1
      b = result[i]
      if overlapxy(brick, b)
        newz = movez(brick, topz(b) + 1)
        push!(result, newz)
        landed = true
        break
      end
    end
    if !landed
      newz = movez(brick, 1)
      push!(result, newz)
    end
    # Sorting result every step is inefficient, but input is small and inserting in the right spot
    # was tricky to get right
    sort!(result, by=topz)
  end
  result
end

function findsupports(bricks)
  [findall(b -> topz(b) == bottomz(brick) - 1 && overlapxy(b, brick), bricks) for brick in bricks]
end

function chainsize(supports, i)
  moving = Set([i])
  chain = 0
  for j in 2:length(supports)
    s = supports[j]
    if !isempty(s) && issubset(s, moving)
      chain += 1
      push!(moving, j)
    end
  end
  chain
end

include("../Runner.jl")
@run_if_main
end

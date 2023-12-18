#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 18
[Read the puzzle](https://adventofcode.com/2023/day/18)

Input is a series of movement instructions with `UDLR` up/down/left/right and a distance, plus a
6-digit hex value.  Those motions describe the edge of a pit to be filled with lava, answer is the
number of total squares of lava (edges plus interior).  In part 1, the hex value is ignored.
In part 2, the hex value is actually five digits of distance and 0/1/2/3 for R/D/L/U.
"""
module Day18
using LinearAlgebra

function part1(lines)
  # The naive way, building a 2D boolean array, floodfilling the outside, and subtracting that
  instructions = parseinput(lines)
  extents = Dict(dir => sum(x -> x.distance, filter(x -> x.direction == dir, instructions))
                 for dir in (UP, DOWN, LEFT, RIGHT))
  lava = zeros(Bool, extents[UP] + extents[DOWN] + 1, extents[LEFT] + extents[RIGHT] + 1)
  center = CartesianIndex(extents[UP] + 1, extents[LEFT] + 1)
  lava[center] = true
  cur = center
  for i in instructions
    for j in 1:(i.distance)
      cur += i.direction
      lava[cur] = true
    end
  end
  exterior = Set{CartesianIndex{2}}()
  q = [CartesianIndex(1, 1)]
  while !isempty(q)
    p = pop!(q)
    if p ∈ exterior
      continue
    end
    push!(exterior, p)
    for dir in (UP, DOWN, LEFT, RIGHT)
      n = p + dir
      if checkbounds(Bool, lava, n) && !lava[n] && n ∉ exterior
        push!(q, n)
      end
    end
  end
  length(lava) - length(exterior)
end

function part2(lines)
  # The smart way, using the [Shoelace formula](https://en.wikipedia.org/wiki/Shoelace_formula)
  instructions = parseinput(lines)
  biginstructions = fromcolor.(instructions)
  pcur = CartesianIndex(0, 0)
  edgelength = 0
  polygon = [pcur]
  for i in biginstructions
    pcur += i.direction * i.distance
    push!(polygon, pcur)
    edgelength += i.distance
  end
  first(polygon) != last(polygon) && error("Can't assume polygon ends on start point")
  pairs = zip(Tuple.(polygon[1:(end - 1)]), Tuple.(polygon[2:end]))
  shoelaceterms = map(((i1, i2),) -> det([first(i1) first(i2); last(i1) last(i2)]), pairs)
  interiorsize = round(Int, abs(sum(shoelaceterms)) / 2)
  interiorsize + edgelength ÷ 2 + 1
end

struct Instruction
  direction::CartesianIndex{2}
  distance::Int
  color::AbstractString
end

const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, 1)

function parseinput(lines)
  dirs = Dict("U" => UP, "D" => DOWN, "L" => LEFT, "R" => RIGHT)
  map(lines) do line
    if (m = match(r"^([RLDU]) (\d+) \(#([a-z0-9]+)\)$", line)) !== nothing
      (dir, dist, color) = m.captures
      Instruction(dirs[dir], parse(Int, dist), color)
    else
      error("bad format for $line")
    end
  end
end

dirnums = Dict('0' => RIGHT, '1' => DOWN, '2' => LEFT, '3' => UP)
function fromcolor(i::Instruction)
  Instruction(dirnums[last(i.color)], parse(Int, i.color[1:(end - 1)], base=16), i.color)
end

include("../Runner.jl")
@run_if_main
end

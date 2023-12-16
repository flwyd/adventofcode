#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 16
[Read the puzzle](https://adventofcode.com/2023/day/16)

Light rays are bouncing a round of grid of mirrors that reflect at a 90° angle (`/\`) or split
into two rays at 90° when striking broadside (`-|`).  Rays pass through empty spaces (`.`) and
the ends of splitters.  When light enters a grid square, that square becomes "energized".
In part 1, a light ray is headed to the right at the top left corner, answer is the count of
energized squares.  In part 2, find the maximal number of energized squares from an entry point.
"""
module Day16

part1(lines) = num_energized(parseinput(lines), Photon(CartesianIndex(1, 1), RIGHT))

function part2(lines)
  grid = parseinput(lines)
  rows = first(axes(grid))
  cols = last(axes(grid))
  edges = vcat([Photon(CartesianIndex(r, first(cols)), RIGHT) for r in rows],
    [Photon(CartesianIndex(r, last(cols)), LEFT) for r in rows],
    [Photon(CartesianIndex(first(rows), c), DOWN) for c in cols],
    [Photon(CartesianIndex(last(rows), c), UP) for c in cols])
  maximum(e -> num_energized(grid, e), edges)
end

function num_energized(grid, start)
  energized = zeros(Bool, axes(grid))
  photons = [start]
  seen = Set{Photon}()
  while !isempty(photons)
    p = pop!(photons)
    if p ∈ seen || p.position ∉ keys(grid)
      continue  # exited the grid
    end
    push!(seen, p)
    energized[p.position] = true
    for heading in MOTIONS[(grid[p.position], p.heading)]
      push!(photons, Photon(p.position + heading, heading))
    end
  end
  count(energized)
end

const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, 1)

const MOTIONS = Dict(('.', UP) => (UP,),
  ('.', DOWN) => (DOWN,),
  ('.', LEFT) => (LEFT,),
  ('.', RIGHT) => (RIGHT,),
  ('/', UP) => (RIGHT,),
  ('/', DOWN) => (LEFT,),
  ('/', LEFT) => (DOWN,),
  ('/', RIGHT) => (UP,),
  ('\\', UP) => (LEFT,),
  ('\\', DOWN) => (RIGHT,),
  ('\\', LEFT) => (UP,),
  ('\\', RIGHT) => (DOWN,),
  ('-', UP) => (LEFT, RIGHT),
  ('-', DOWN) => (LEFT, RIGHT),
  ('-', LEFT) => (LEFT,),
  ('-', RIGHT) => (RIGHT,),
  ('|', UP) => (UP,),
  ('|', DOWN) => (DOWN,),
  ('|', LEFT) => (UP, DOWN),
  ('|', RIGHT) => (UP, DOWN))

struct Photon
  position::CartesianIndex{2}
  heading::CartesianIndex{2}
end

parseinput(lines) = permutedims(reduce(hcat, collect.(lines)), (2, 1))

include("../Runner.jl")
@run_if_main
end

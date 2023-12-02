#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 2
[Read the puzzle](https://adventofcode.com/2023/day/2)

Input is lines with numbered games consisting of one or rounds of 0 or more red, green, and blue
cubes.  Part 1's answer is the sum of game IDs which could be played with a bag of 12 red, 13 green,
and 14 blue cubes.  Part 2's answer is the sum of the "power" of the minimal number of cubes that
could be used to play each game.  The power of a cube set is the product of red, green, and blue.
"""
module Day2

struct Cubeset
  red::Int
  green::Int
  blue::Int
end

struct Game
  id::Int
  sets::T where {T <: AbstractArray{Cubeset}}
end

function part1(lines)
  isvalid(c::Cubeset) = c.red <= 12 && c.green <= 13 && c.blue <= 14
  sum(map(g -> g.id, filter(g -> all(isvalid, g.sets), parseinput(lines))))
end

function part2(lines)
  sum(power ∘ minset, parseinput(lines))
end

function power(cs::Cubeset)
  cs.red * cs.green * cs.blue
end

function minset(g::Game)
  Cubeset(maximum(map(x -> x.red, g.sets)),
    maximum(map(x -> x.green, g.sets)),
    maximum(map(x -> x.blue, g.sets)))
end

function parseinput(lines)
  map(lines) do line
    (gnum, rest) = split(line, ": ")
    clusters = split(rest, "; ")
    sets = map(clusters) do cluster
      c = split(cluster, ", ")
      Cubeset(findcolor("red", c), findcolor("green", c), findcolor("blue", c))
    end
    Game(parse(Int, chopprefix(gnum, "Game ")), sets)
  end
end

function findcolor(color, cubes)
  found = get(cubes, something(findfirst(endswith(" $color"), cubes), 0), "0 $color")
  parse(Int, strip(!isdigit, found))
end

include("../Runner.jl")
@run_if_main
end

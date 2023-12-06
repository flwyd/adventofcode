#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 6
[Read the puzzle](https://adventofcode.com/2023/day/6)

Input is two lines, a list of times and a list of distances describing race duration and record
distance.  Start the race by charging your boat for N time units, giving it N distance per time unit
speed during the rest of the race.  Part 1 is the product of the number of ways to win each race.
Part 2 concatenates each number and is the total number of ways of winning that one race.
"""
module Day6

function part1(lines)
  prod([winning_moves.(x, y) for (x, y) in zip(parseinput(lines)...)])
end

function part2(lines)
  winning_moves(parse.(Int, join.(parseinput(lines)))...)
end

function parseinput(lines)
  times = parse.(Int, split(chopprefix(lines[1], "Time:")))
  dists = parse.(Int, split(chopprefix(lines[2], "Distance:")))
  (times, dists)
end

winning_moves(time, dist) = count(i -> (time - i) * i > dist, 1:(time - 1))

include("../Runner.jl")
@run_if_main
end

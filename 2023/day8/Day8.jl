#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 8
[Read the puzzle](https://adventofcode.com/2023/day/8)

First line of input is a series of L and R characters indicating whether to
go left or right, cycling infinitely.  Remaining lines are `DEF = (GHI, JKL)`
meaning node `DEF` has `GHI` to the left and `JKL` to the right.
Part 1 is the number of steps from AAA to ZZZ.
Part 2 starts simultaneously on all nodes ending with `A` and ends when all
paths simultaneously reach a node ending with `Z`.
"""
module Day8

function part1(lines)
  # exaample3 doesn't have AAA/ZZZ
  normal = any(startswith("AAA ="), lines)
  solution(lines, ==(normal ? "AAA" : "11A"), ==(normal ? "ZZZ" : "11Z"))
end

part2(lines) = solution(lines, endswith('A'), endswith('Z'))

function solution(lines, start_predicate, end_predicate)
  steps, graph = parseinput(lines)
  steplen = length(lines[1])
  local cur = collect(keys(graph) |> filter(start_predicate))
  zcycles = zeros(Int, length(cur))
  numsteps = 0
  for dir in steps
    if numsteps % steplen == 0
      for (i, first) in enumerate(zcycles)
        if first == 0 && end_predicate(cur[i])
          zcycles[i] = numsteps
        end
      end
      if all(>(0), zcycles)
        return lcm(zcycles)
      end
    end
    numsteps += 1
    cur = [graph[c][dir == 'L' ? 1 : 2] for c in cur]
  end
end

function parseinput(lines)
  steps = Iterators.cycle([c for c in lines[1]])
  graph = Dict{AbstractString, Tuple{String, String}}()
  map(lines) do line
    if (m = match(r"^(\w+) = \((\w+), (\w+)\)$", line)) !== nothing
      node, left, right = m.captures
      graph[node] = (left, right)
    end
  end
  steps, graph
end

include("../Runner.jl")
@run_if_main
end

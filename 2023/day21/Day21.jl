#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 21
[Read the puzzle](https://adventofcode.com/2023/day/21)
"""
module Day21

function part1(lines)
  grid = parseinput(lines)
  numrounds = size(grid, 1) < 100 ? 6 : 64
  rounds = zeros(Bool, (size(grid)..., numrounds+1))
  rounds[findfirst(==('S'), grid), 1] = true
  for round in 1:numrounds
    for i in eachindex(IndexCartesian(), grid)
      if grid[i] != '#'
        for x in neighbors(grid, i)
          if rounds[x, round]
            rounds[i, round + 1] = true
          end
        end
      end
    end
  end
  # for i in axes(rounds, 1)
  #   println(join(map(j -> rounds[i,j,numrounds+1] ? 'O' : grid[i,j], axes(rounds, 2))))
  # end
  count(rounds[:,:,numrounds+1])
end

function part2(lines)
  grid = parseinput(lines)
  totalsteps = 50
  start = findfirst(==('S'), grid)
  @show center = crawl(grid, start)
  crawled = Dict(start => center)
  cardinal = [crawl(grid, entrypoint(grid, center.exits[i], NEIGHBORS[i])) for i in 1:4]
  @show cardinal
  if true
    return :TODO
  end
  for i in 1;4
    crawled[cardinal[i].entry] = cardinal[i]
  end
  # actual input has straight openings through the center but example reaches some corners
  # faster than others
  corners = ((UP, LEFT), (RIGHT, UP), (DOWN, LEFT), (RIGHT, DOWN))
  for (a, b) in corners
    entry = entrypoint(grid, cardinal[a].exits[b])
    crawled[entry] = crawl(grid, entry)
  end
  total = iseven(totalsteps) ? center.event : center.odd
  for i in 1:4
    dir = NEIGHBORS[i]
    pos = start
    crawl = crawled[start]
    steps = 0
    while steps < totalsteps
      entry = entrypoint(grid, crawl.exits[dir])
      steps += crawl.stepsacross[dir]
    end
    steps = crawl.stepsacross[i]
  end
  # println(join(cardinal, "\n"))
  :TODO
end

parseinput(lines) = reduce(hcat, collect.(lines))

const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(+1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, +1)
const NEIGHBORS = (UP, DOWN, LEFT, RIGHT)

neighbors(grid, i) = filter(n -> checkbounds(Bool, grid, n), map(x -> i + x, NEIGHBORS))

struct Crawl
  oddcount::Int
  evencount::Int
  entry::CartesianIndex{2}
  exits::Vector{CartesianIndex{2}}
  stepsacross::Vector{Int}
end

function entrypoint(grid, exit, dir)
  row, col = Tuple(exit)
  if dir == UP
    CartesianIndex(size(grid, 1), col)
  elseif dir == DOWN
    CartesianIndex(1, col)
  elseif dir == LEFT
    CartesianIndex(row, size(grid, 2))
  elseif dir == RIGHT
    CartesianIndex(row, 1)
  end
end

function crawl(grid, start)
  numrounds = sum(size(grid))
  rounds = zeros(Bool, (size(grid)..., numrounds+1))
  rounds[start, 1] = true
  edges = repeat([CartesianIndex(0, 0)], 4)
  edgesteps = repeat([0], 4)
  for round in 1:numrounds
    for i in eachindex(IndexCartesian(), grid)
      if grid[i] != '#'
        for x in neighbors(grid, i)
          if rounds[x, round]
            rounds[i, round + 1] = true
            for j in 1:4
              if edgesteps[j] == 0 && !checkbounds(Bool, grid, i + NEIGHBORS[j])
                edges[j] = i
                edgesteps[j] = round
              end
            end
          end
        end
      end
    end
  end
  odd, even = if iseven(numrounds)
    count(rounds[:,:,numrounds+1]), count(rounds[:,:,numrounds]) 
  else
    count(rounds[:,:,numrounds]), count(rounds[:,:,numrounds+1])
  end
  Crawl(odd, even, start, edges, edgesteps)
end

include("../Runner.jl")
@run_if_main
end

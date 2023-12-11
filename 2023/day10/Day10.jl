#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 10
[Read the puzzle](https://adventofcode.com/2023/day/10)

Input is a grid of pipes with `-|` as horizontal and vertical and `JF7L` as corners. `S` is a
pipe of unidentified type (but it connects to two others) and `.` is floor without pipe.
The pipe conneted to `S` forms a loop.
Part 1 answer is the distance of the furthest point from `S`.
Part 2 answer is the number of points topologically contained by the loop, not including points
that make up the loop.
"""
module Day10
# TODO clean up this implementation

function part1_old(lines)
  input, start = parseinput(lines)
  start = findfirst(p -> p.shape == 'S', input)
  seen = [start]
  q = [(start, 0)]
  local furthest = 0
  while !isempty(q)
    i, dist = popfirst!(q)
    furthest = max(dist, furthest)
    unseen = filter(!in(seen), input[i].neighbors)
    push!(seen, unseen...)
    push!(q, map(x -> (x, dist + 1), unseen)...)
  end
  furthest
end

function part2_old(lines)
  input, start = parseinput(lines)
  left_islands = Set{CartesianIndex}()
  right_islands = Set{CartesianIndex}()
  cur = start
  next = first(input[start].neighbors)
  while next != start
    dir = next - cur
    left = cur + LEFT_HAND[dir]
    right = cur + RIGHT_HAND[dir]
    if left ∉ left_islands && left ∈ keys(input) && input[left].shape == '.'
      left_islands = left_islands ∪ island(input, left)
    end
    if right ∉ right_islands && right ∈ keys(input) && input[right].shape == '.'
      right_islands = right_islands ∪ island(input, right)
    end
    cur, next = next, only(filter(!=(cur), input[next].neighbors))
  end
  islands = any(x -> any(==(1), Tuple(x)), left_islands) ? right_islands : left_islands
  println(stderr, "Left: $(length(left_islands)), Right: $(length(right_islands))")
  length(islands)
end

function part1(lines)
  grid, start = parseinput(lines)
  Int(ceil(length(chain(grid, start))/2))
end


function part2(lines)
  grid, start = parseinput(lines)
  loop = chain(grid, start)
  # count_ray_casts(grid, loop)
  # println("left")
  left = new_island(grid, loop, start, LEFT_HAND)
  # println("right")
  right = new_island(grid, loop, start, RIGHT_HAND)
  islands = any(x -> any(==(1), Tuple(x)), left) ? right : left
  # lonely = setdiff(eachindex(IndexCartesian(), grid), loop, left, right)
  # println(stderr, "Left: $(length(left)), Right: $(length(right))")
  # println(stderr, "Lonely: $(length(lonely)) $lonely")
  # println(stderr, lonely)
  # ascii = permutedims(map(grid) do p
  #   if p.position ∈ right
  #     '@'
  #   elseif p.position ∈ loop
  #     p.shape
  #   elseif p.position ∈ lonely
  #     '#'
  #   else
  #     '.'
  #   end
  # end)
  # println(join(map(join, eachrow(ascii)), "\n"))
  length(islands)
end

# Implementation of https://en.wikipedia.org/wiki/Point_in_polygon#Ray_casting_algorithm but
# it's failing for rays that pass along a line e.g. `.L-J.`.  "Crossing an edge" logic needs
# more nuance.
function count_ray_casts(grid, loop)
  result = 0
  for i in eachindex(IndexCartesian(), grid)
    if i in loop
      println("$(Tuple(i)) in loop")
      continue
    end
    row, col = Tuple(i)
    crosses = 0
    for j in 1:col-1
      p = CartesianIndex(row, j)
      if p ∈ loop
        println("$(Tuple(i)) crosses at $(Tuple(p)) $(grid[p])")
        crosses += 1
      end
    end
    if isodd(crosses)
      result += 1
    end
  end
  return result
end

function new_island(grid, chain, start, hand)
  result = Set(empty(chain))
  chainset = Set(chain)
  for (cur, next) in zip(chain, Iterators.flatten([Iterators.drop(chain, 1), [start]]))
    for z in [cur, next]
    point = z + hand[next - cur]
    if point ∉ chainset
      q = [point]
      while !isempty(q)
        p = pop!(q)
        if p ∉ chainset && p ∉ result
          push!(result, p)
          neighbors = map(x -> p + x, [NORTH, EAST, SOUTH, WEST])
          push!(q, filter(in(keys(grid)), neighbors)...)
        end
      end
    end
  end
  end
  # ascii = permutedims(map(grid) do p
  #   if p.position ∈ result
  #     '@'
  #   elseif p.position ∈ chain
  #     p.shape
  #   else
  #     '.'
  #   end
  # end)
  # println(join(map(join, eachrow(ascii)), "\n"))
  result
end

function chain(grid, start)
  result = [start]
  cur = start
  next = first(grid[start].neighbors)
  while next != start
    push!(result, next)
    cur, next = next, only(filter(!=(cur), grid[next].neighbors))
  end
  result
end

function island(grid, point)
  seen = Set{CartesianIndex{2}}()
  q = [point]
  while !isempty(q)
    p = pop!(q)
    if p ∉ seen && grid[p].shape == '.'
      push!(seen, p)
      neighbors = map(x -> p + x, [NORTH, EAST, SOUTH, WEST])
      push!(q, filter(in(keys(grid)), neighbors)...)
    end
  end
  seen
end

const NORTH = CartesianIndex(0, -1)
const SOUTH = CartesianIndex(0, +1)
const EAST = CartesianIndex(+1, 0)
const WEST = CartesianIndex(-1, 0)
const LEFT_HAND = Dict(NORTH => WEST, SOUTH => EAST, EAST => NORTH, WEST => SOUTH)
const RIGHT_HAND = Dict(NORTH => EAST, SOUTH => WEST, EAST => SOUTH, WEST => NORTH)

struct Pipe
  shape::Char
  position::CartesianIndex{2}
  neighbors::Vector{CartesianIndex{2}}
end
const SHAPES = Dict('|' => [NORTH, SOUTH],
  '-' => [EAST, WEST],
  'L' => [NORTH, EAST],
  'J' => [NORTH, WEST],
  'L' => [NORTH, EAST],
  '7' => [SOUTH, WEST],
  'F' => [SOUTH, EAST],
  '.' => [],
  'S' => [])
function parseinput(lines)
  shapes = reduce(hcat, collect(line) for line in lines)
  grid = map(collect(pairs(IndexCartesian(), shapes))) do (i, c)
    neighbors = filter(in(keys(shapes)), [i + x for x in SHAPES[c]])
    Pipe(c, i, neighbors)
  end
  grid[CartesianIndex(3, 2)]
  start = findfirst(p -> p.shape == 'S', grid)
  neighbors = [start + x for x in [NORTH, SOUTH, EAST, WEST]]
  inbounds = filter(n -> n in keys(grid), neighbors)
  connected = filter(n -> start in grid[n].neighbors, inbounds)
  grid[start] = Pipe('S', start, collect(connected))
  grid, start
end

include("../Runner.jl")
@run_if_main
end

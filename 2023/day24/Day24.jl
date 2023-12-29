#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 24
[Read the puzzle](https://adventofcode.com/2023/day/24)

Input is initial position and velocity vector of hailstones in 3D.
Part 1 is the number of pairs of hailstones which will collide when projected into (x, y).
Part 2 is the sum of (x, y, z) for the initial position of a hailstone which would collide with
all other stones in the input.
"""
module Day24

using JuMP
using Ipopt

function part1(lines)
  input = parseinput(lines)
  space = first(input).x < 100 ? (7.0, 27.0) : (200000000000000.0, 400000000000000.0)
  num = length(input)
  outcomes = [intersect2d(input[i], input[j], space) for i in 1:(num - 1) for j in (i + 1):num]
  count(==(:intersect), outcomes)
end

function part2(lines)
  input = parseinput(lines)
  # Focus on the "corners", stones moving towards from the center, though this may be a bit of
  # stupid luck since ipopt ends up exceeding the iteration limit with this set, though it fails
  # with local infeasibility with some other stone sets
  bysigns = Dict()
  for s in input
    signed = sign.((s.dx, s.dy, s.dz))
    if !haskey(bysigns, signed)
      bysigns[signed] = Stone[]
    end
    push!(bysigns[signed], s)
  end
  # all example stones but one are going in the same direction
  corners = length(bysigns) < 6 ? input : first.([
    sort(bysigns[(1, -1, -1)]; by=s -> s.x),
    sort(bysigns[(-1, 1, -1)]; by=s -> s.y),
    sort(bysigns[(-1, -1, 1)]; by=s -> s.z),
    sort(bysigns[(-1, 1, 1)]; by=s -> -s.x),
    sort(bysigns[(1, -1, 1)]; by=s -> -s.y),
    sort(bysigns[(1, 1, -1)]; by=s -> -s.z),
  ])
  # Ipopt fails to find a solution on the final three corners, but the first three work ¯\(°_o)/¯
  s1, s2, s3 = corners[1:3]
  mincoord = minimum(min(s.x, s.y, s.z) for s in input)
  maxcoord = maximum(max(s.x, s.y, s.z) for s in input)
  maxvel = maximum(max(abs(s.dx), abs(s.dy), abs(s.dz)) for s in input)
  model = Model(Ipopt.Optimizer)
  set_attribute(model, "print_level", 2) # don't print everything the optimizer is doing
  set_attribute(model, "sb", "yes") # don't print Ipopt license
  @variable(model, maxcoord*2 >= x >= mincoord÷2)
  @variable(model, maxcoord*2 >= y >= mincoord÷2)
  @variable(model, maxcoord*2 >= z >= mincoord÷2)
  @variable(model, -maxvel <= dx <= maxvel)
  @variable(model, -maxvel <= dy <= maxvel)
  @variable(model, -maxvel <= dz <= maxvel)
  @variable(model, t1 >= 1)
  @variable(model, t2 >= 1)
  @variable(model, t3 >= 1)
  @constraint(model, c1x, x + dx * t1 == s1.x + s1.dx * t1)
  @constraint(model, c1y, y + dy * t1 == s1.y + s1.dy * t1)
  @constraint(model, c1z, z + dz * t1 == s1.z + s1.dz * t1)
  @constraint(model, c2x, x + dx * t2 == s2.x + s2.dx * t2)
  @constraint(model, c2y, y + dy * t2 == s2.y + s2.dy * t2)
  @constraint(model, c2z, z + dz * t2 == s2.z + s2.dz * t2)
  @constraint(model, c3x, x + dx * t3 == s3.x + s3.dx * t3)
  @constraint(model, c3y, y + dy * t3 == s3.y + s3.dy * t3)
  @constraint(model, c3z, z + dz * t3 == s3.z + s3.dz * t3)
  optimize!(model)
  if (status = termination_status(model)) !== LOCALLY_SOLVED
    @warn "Solver status is $status, answer might be incorrect"
  end
  # for vars in ((x, y, z), (dx, dy, dz), (t1, t2, t3))
  #   println(stderr,
  #   join(["$v: $(round(Int, value(v))) ± $(abs(value(v) - round(Int, value(v))))" for v in vars],
  #   " "))
  # end
  sum(round(Int, value(v)) for v in (x, y, z))
end

struct Stone
  x::Int
  y::Int
  z::Int
  dx::Int
  dy::Int
  dz::Int
end

function intersect2d(a::Stone, b::Stone, bounds)
  low, high = bounds
  aslope = a.dy / a.dx
  bslope = b.dy / b.dx
  if aslope ≈ bslope
    return :parallel
  end
  aint = a.y - aslope * a.x
  bint = b.y - bslope * b.x
  res = [-aslope 1; -bslope 1] \ [aint, bint]
  if !all(p -> low ≤ p ≤ high, res)
    return :outside
  end
  px, py = res
  if sign(a.dx) * a.x > sign(a.dx) * px || sign(b.dx) * b.x > sign(b.dx) * px ||
     sign(a.dy) * a.y > sign(a.dy) * py || sign(b.dy) * b.y > sign(b.dy) * py
    return :before
  end
  return :intersect
end

function parseinput(lines)
  map(lines) do line
    coords, vel = split(line, " @ ")
    x, y, z = parse.(Int, split(coords, ", "))
    dx, dy, dz = parse.(Int, split(vel, ", "))
    Stone(x, y, z, dx, dy, dz)
  end
end

include("../Runner.jl")
@run_if_main
end

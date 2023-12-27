#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 24
[Read the puzzle](https://adventofcode.com/2023/day/24)
"""
module Day24

using Symbolics

TOOHIGH = [653419564351753]

function part1(lines)
  input = parseinput(lines)
  count(==(:intersect),
    [intersect2d(input[i], input[j], coordrange(input)) for i in 1:(length(input) - 1)
     for j in (i + 1):length(input)])
end

function part2(lines)
  input = parseinput(lines)

  bysigns = Dict()
  for s in input
    signed = sign.((s.dx, s.dy, s.dz))
    if !haskey(bysigns, signed)
      bysigns[signed] = Stone[]
    end
    push!(bysigns[signed], s)
  end
  corners = length(bysigns) < 6 ? input : first.([
    sort(bysigns[(1, -1, -1)]; by=s -> s.x),
    sort(bysigns[(-1, 1, -1)]; by=s -> s.y),
    sort(bysigns[(-1, -1, 1)]; by=s -> s.z),
    sort(bysigns[(-1, 1, 1)]; by=s -> -s.x),
    sort(bysigns[(1, -1, 1)]; by=s -> -s.y),
    sort(bysigns[(1, 1, -1)]; by=s -> -s.z),
  ])

  # for stones in Iterators.partition(input, 20)
    eqs, ans, times = symbolize(corners)
    for tval in (length(lines) < 10 ? (1:10) : (1:1_000_000_000))
      for (i, t) in enumerate(times)
        sub = Symbolics.substitute.(eqs, (Dict(t => tval),))
        solved, timesolved... = Symbolics.solve_for(sub, vcat(ans, times[1:i-1], times[(i + 1):end]))
        if solved > 0 && all(>(0), timesolved)
          closest = input[i]
          if isinteger(solved)
            println("$t=$tval $(Int(solved)) $closest")
          else
            println("non-integer t1=$t $solved $(round(solved)) $closest")
          end
        end
      end
    end
  # end
  :TODO
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

function symbolize(stones)
  @variables ans
  times = Num[]
  eqs = map(enumerate(stones)) do (i, s)
    t = Symbolics.variable(Symbol("t$i"))
    push!(times, t)
    f = s.x + s.y + s.z + (s.dx + s.dy + s.dz) * t
    f ~ ans
  end
  eqs, ans, times
end

function parseinput(lines)
  map(lines) do line
    coords, vel = split(line, " @ ")
    x, y, z = parse.(Int, split(coords, ", "))
    dx, dy, dz = parse.(Int, split(vel, ", "))
    Stone(x, y, z, dx, dy, dz)
  end
end

function coordrange(stones)
  first(stones).x < 100 ? (7.0, 27.0) : (200000000000000.0, 400000000000000.0)
end

include("../Runner.jl")
@run_if_main
end

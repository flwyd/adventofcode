#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 5
[Read the puzzle](https://adventofcode.com/2023/day/5)

First line of the input file is "seeds:" followed by a list of integers.
Rest of the input is paragraphs started with "foo-to-bar map:" and followed by
one or more sets of three integers.  The first number is the "destination",
second is the "source", and third is the "length" describing a mapping from
source+x to destination+x where x is 0:length-1.  Determining where a seed goes
requires transforming the number from source to destination through each map,
starting with seed-to-soil and ending with humidity-to-location.  If a source
value isn't part of a mapped range it retains its value.

Part 1 is the smallest location that any of the input seeds lands in.
Part 2 treats the "seeds:" lines as ranges of seeds, the result is the lowest
location which has any seed associated with it.
"""
module Day5

struct MapRange
  range::UnitRange{Int}
  dest::Int
end

struct Mapping
  name::String
  ranges::Vector{MapRange}
end

Base.isless(x::MapRange, y::MapRange) = x.range < y.range

function part1(lines)
  seeds, maps = parseinput(lines)
  minimum([seed_to_location(maps, s) for s in seeds])
end

function part2(lines)
  (seeds, maps) = parseinput(lines)
  seedranges = sort(map(x -> x[1]:(x[1] + x[2] - 1), Iterators.partition(seeds, 2)))
  sliced = Mapping[infill(first(maps))]
  for i in 2:length(maps)
    push!(sliced, splitranges(sliced[i - 1], infill(maps[i])))
  end
  low_locations = map(x -> first(x.dest), last(sliced).ranges)
  seedsbylocation = [(l, location_to_seed(maps, l)) for l in low_locations]
  matches = seedsbylocation |> filter(x -> any(y -> x[2] in y, seedranges))
  minimum(map(first, matches))
end

function parseinput(lines)
  seeds = parse.(Int, split(chopprefix(lines[1], "seeds: ")))
  maps = Mapping[]
  for line in lines[3:end]
    if endswith(line, " map:")
      push!(maps, Mapping(chopsuffix(line, " map:"), Mapping[]))
    elseif !isempty(line)
      (dest, source, len) = parse.(Int, split(line))
      push!(last(maps).ranges, MapRange(source:(source + len - 1), dest))
    end
  end
  for m in maps
    sort!(m.ranges)
  end
  (seeds, maps)
end

"""Returns the location a seed number will be planted in, assuming locations are
the output of the last Mapping in maps and seeds are the input to the first."""
function seed_to_location(maps, seed)
  foldl((val, map) -> indirect(map, val), maps; init=seed)
end

"""Returns `value` possibly adjusted by `from`'s mapping."""
function indirect(from::Mapping, value)
  matches = from.ranges |> filter(r -> value in r.range)
  if isempty(matches)
    value
  else
    m = only(matches)
    value - first(m.range) + m.dest
  end
end

"""Returns the seed number that would land in location, assuming locations are
the output of the last Mapping in maps and seeds are the input to the first."""
function location_to_seed(maps, location)
  foldl((val, map) -> backwards(map, val), reverse(maps); init=location)
end

"""Returns the input to `indirect` which would return `value`."""
function backwards(from::Mapping, value)
  for mr in from.ranges
    if 0 <= value - mr.dest < length(mr.range)
      return value - mr.dest + first(mr.range)
    end
  end
  value
end

function splitranges(from::Mapping, to::Mapping)
  result = []
  for fmr in from.ranges
    for tmr in to.ranges
      dr = (fmr.dest):(fmr.dest + length(fmr.range) - 1)
      overlap = dr ∩ tmr.range
      if !isempty(overlap)
        push!(result,
          MapRange(overlap, tmr.dest + (first(overlap) - first(tmr.range))))
      end
    end
  end
  Mapping(to.name, result)
end

function infill(map::Mapping)
  highest_possible = 2^32
  result = MapRange[]
  nextstart = 0
  for mr in map.ranges
    if nextstart < first(mr.range)
      push!(result, MapRange(nextstart:(first(mr.range) - 1), nextstart))
    end
    nextstart = last(mr.range) + 1
    push!(result, mr)
  end
  push!(result, MapRange(nextstart:highest_possible, nextstart))
  Mapping(map.name, result)
end

include("../Runner.jl")
@run_if_main
end

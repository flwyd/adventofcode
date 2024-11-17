#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 12
[Read the puzzle](https://adventofcode.com/2023/day/12)
"""
module Day12

function part1(lines)
  input = parseinput(lines)
  map(input) do pat
    count_permutations(pat, Dict{String, Int}())
  end |> sum
end

function part2(lines)
  input = parseinput(lines)
  map(input) do pat
    cache = Dict{String, Int}()
    copies = [pat.chars for _ in 1:5]
    big = Pattern(join(copies, "?"), repeat(pat.runs, 5))
    count_permutations(big, Dict{String, Int}())
  end |> sum
end

struct Pattern
  chars::AbstractString
  runs::Vector{Int}
end

function parseinput(lines)
  map(lines) do line
    chars, ints = split(line)
    Pattern(chars, parse.(Int, split(ints, ",")))
  end
end

const MAX_INT = typemax(Int)
function count_permutations(pat::Pattern, cache::Dict{String, Int})
  if isempty(pat.runs)
    return '#' ∈ pat.chars ? 0 : 1
  end
  if sum(pat.runs) > length(pat.chars)
    return 0
  end
  key = "$(pat.chars) $(join(pat.runs, ","))"
  if key in keys(cache)
    return cache[key]
  end
  firsthash = something(findfirst('#', pat.chars), MAX_INT)
  firstquest = something(findfirst('?', pat.chars), MAX_INT)
  if firsthash > 1 && firstquest > 1
    next = Pattern(pat.chars[min(firsthash, firstquest):end], pat.runs)
    return cache[key] = count_permutations(next, cache)
  end
  if firsthash == 1
    runend = first(pat.runs)
    for i in 2:runend
      if pat.chars[i] == '.'
        # not enough #s or ?s to satisfy this run
        return cache[key] = 0
      end
    end
    if length(pat.chars) == runend
      return cache[key] = length(pat.runs) == 1
    end
    @assert length(pat.chars) > runend
    if pat.chars[runend + 1] == '#'
      # too many #s or ?s to satisfy this run
      return cache[key] = 0
    end
    nextruns = collect(Iterators.drop(pat.runs, 1))
    nextchars = pat.chars[runend + 1] == '?' ? '.' * pat.chars[(runend + 2):end] :
                pat.chars[(runend + 1):end]
    next = Pattern(nextchars, nextruns)
    return cache[key] = count_permutations(next, cache)
  end
  @assert firstquest == 1
  rest = pat.chars[2:end]
  asdot = count_permutations(Pattern(rest, pat.runs), cache)
  ashash = count_permutations(Pattern('#' * rest, pat.runs), cache)
  return cache[key] = asdot + ashash
end

include("../Runner.jl")
@run_if_main
end

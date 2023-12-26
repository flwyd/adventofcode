#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 25
[Read the puzzle](https://adventofcode.com/2023/day/25)
"""
module Day25

function part1(lines)
  input = parseinput(lines)
  alledges = reverse(unique(sort(map(Tuple,
    (Iterators.flatten(map(k -> [sort([k, w]) for w in input[k]], collect(keys(input)))))))))
  for i in 1:length(alledges)
    for j in (i + 1):length(alledges)
      for k in (j + 1):length(alledges)
        a, b, c = alledges[i], alledges[j], alledges[k]
        if ispartitioned(input, (a, b, c))
          println("Partitioned: $a, $b, $c")
        end
      end
    end
  end
  # get partition sizes
  :TODO
end

part2(lines) = "Merry Christmas"

function parseinput(lines)
  graph = Dict{String, Vector{String}}()
  map(lines) do line
    key, vals = split(line, ": ")
    if !haskey(graph, key)
      graph[key] = String[]
    end
    for v in split(vals, " ")
      push!(graph[key], v)
      if !haskey(graph, v)
        graph[v] = String[]
      end
      push!(graph[v], key)
    end
  end
  graph
end

function ispartitioned(graph, without)
  start = first(keys(graph))
  seen = Set([start])
  q = [start]
  while !isempty(q)
    n = popfirst!(q)
    for v in graph[n]
      if (n, v) ∈ without || (v, n) ∈ without
        continue
      end
      if v ∉ seen
        push!(seen, v)
        push!(q, v)
      end
    end
  end
  if length(seen) != length(graph)
    @show (length(seen), length(graph) - length(seen), length(seen) * (length(graph) - length(seen)))
    return true
  end
  return false
end

include("../Runner.jl")
@run_if_main
end

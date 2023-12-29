#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 25
[Read the puzzle](https://adventofcode.com/2023/day/25)

Input is `source: target1 target2…` edges in an undirected graph.  If three
edges are cut, the graph will have two connected components.  Result is the
product of the sizes of those two compoonents.
"""
module Day25

function part1(lines)
  edges, graph = parseinput(lines)
  dists = zeros(Int, size(edges))
  for i in 1:(size(edges, 1) - 1)
    seen = BitSet([i])
    q = [(i, 0)]
    while !isempty(q)
      cur, dist = popfirst!(q)
      for j in graph[cur]
        if j ∉ seen
          dists[i, j] = dists[j, i] = dist + 1
          push!(seen, j)
          push!(q, (j, dist + 1))
        end
      end
    end
  end
  maxs = sort([(maximum(dists[i, :]), i) for i in axes(edges, 1)])
  lowest = map(last, Iterators.takewhile(x -> x[1] == maxs[1][1], maxs))
  if length(lowest) == 6
    cuts = [(i, j) for i in lowest, j in lowest if i < j && edges[i, j]]
    @assert length(cuts) == 3
    return componentsizes(cutedges(edges, cuts), cuts[1]...) |> prod
  end
  @assert length(lowest) >= 3
  lowest, rest = map(last, maxs[1:3]), map(last, maxs[4:end])
  for i in rest, j in rest, k in rest
    if i == j || j == k || i == k
      continue
    end
    cuts = zip(lowest, [i, j, k])
    if any(c -> !edges[c...], cuts)
      continue
    end
    res = componentsizes(cutedges(edges, cuts), first(cuts)...) |> prod
    res != 0 && return res
  end
  throw("Did not find any valid cuts")
end

part2(lines) = "Merry Christmas"

function cutedges(edges, cuts)
  res = copy(edges)
  for (i, j) in cuts
    res[i, j] = res[j, i] = false
  end
  res
end

function componentsizes(edges, starta::Int, startb::Int)
  res = Int[]
  for (n, oops) in ((starta, startb), (startb, starta))
    num = 1
    seen = BitSet([n])
    q = [n]
    while !isempty(q)
      cur = popfirst!(q)
      for m in findall(edges[cur, :])
        if m == oops # cutset didn't create separate components
          return [0, 0]
        end
        if m ∉ seen
          num += 1
          push!(seen, m)
          push!(q, m)
        end
      end
    end
    push!(res, num)
  end
  res
end

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
  nodes = collect(keys(graph))
  edges = zeros(Bool, length(nodes), length(nodes))
  intgraph = [Int[] for _ in 1:length(graph)]
  for (i, n) in enumerate(nodes)
    for m in graph[n]
      j = findfirst(==(m), nodes)
      edges[i, j] = true
      push!(intgraph[i], findfirst(==(m), nodes))
    end
  end
  edges, intgraph
end

include("../Runner.jl")
@run_if_main
end

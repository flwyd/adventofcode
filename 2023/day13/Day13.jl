#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 13
[Read the puzzle](https://adventofcode.com/2023/day/13)

Input is blank-delimited grids of `#` and `.` which is symmetrical around one vertical or horizontal
line, possibly ignoring extra rows/columns at the edge.  Score is the number of columns to the left
of the split line for vertical splits and 100 times the number of rows above the split line for
horizontal.  Part 1 is the sum of scores for each grid in the input.   In part 2 it is disclosed
that toggling one point will create a new veritical or horizontal split; result is the sum of scores
of the new splits, ignoring the original split if it's still a valid mirror line.
"""
module Day13

part1(lines) = map(score_part1, parseinput(lines)) |> sum
part2(lines) = map(score_part2, parseinput(lines)) |> sum

function parseinput(lines)
  paragraphs = []
  start = 1
  while true
    blank = findnext(isempty, lines, start)
    paragraph = blank === nothing ? lines[start:end] : lines[start:blank-1]
    push!(paragraphs, reduce(hcat, collect.(paragraph)))
    blank === nothing && break
    start = blank + 1
  end
  paragraphs
end

function mirror(grid, dim)
  matched = Int[]
  for i in 1:size(grid, dim)-1
    len = min(i, size(grid, dim)-i)
    before = selectdim(grid, dim, (i+1-len):i)
    after = reverse(selectdim(grid, dim, (i+1):(i+len)); dims=dim)
    if before == after
      push!(matched, i)
    end
  end
  matched
end

vertical_mirror(grid) = mirror(grid, 1)
horizontal_mirror(grid) = mirror(grid, 2)

function score_part1(grid)
  v = vertical_mirror(grid)
  h = horizontal_mirror(grid)
  if isempty(v) == isempty(h)
    error("Expected one of vertical or horizontal, not $v $h")
  end
  isempty(v) ? 100*only(h) : only(v)
end

function score_part2(grid)
  olds = (vertical_mirror(grid), horizontal_mirror(grid))
  factors = (1, 100)
  # oldv = vertical_mirror(grid)
  # oldh = horizontal_mirror(grid)
  for (i, p) in enumerate(grid)
    g = copy(grid)
    g[i] = p == '#' ? '.' : '#'
    mirrored = (vertical_mirror(g), horizontal_mirror(g))
    for (m, old, factor) in zip(mirrored, olds, factors)
      diff = setdiff(m, old)
      if !isempty(diff)
        return factor * only(diff)
      end
    end
    # v = vertical_mirror(g)
    # vdiff = setdiff(v, oldv)
    # if !isempty(vdiff)
    #   return only(vdiff)
    # end
    # h = horizontal_mirror(g)
    # hdiff = setdiff(h, oldh)
    # if !isempty(hdiff)
    #   return 100 * only(hdiff)
    # end
  end
end

include("../Runner.jl")
@run_if_main
end

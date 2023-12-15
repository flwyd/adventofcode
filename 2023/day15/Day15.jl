#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 15
[Read the puzzle](https://adventofcode.com/2023/day/15)

Input is a single line of comma-separated strings which are a label and an operation.
A hash function is defined.  Part 1 is the sum of the hash function on each string.
In part 2, the label determines the box to perform the operation in.  Operation `-` removes a
lens with that label from the box, if any.  Operation `=N` replaces the labeled lens (if any)
in the box with one of power `N`, or appends the lens to the box.  Result is the sum of
`box_number * lens_position * lens_power`.
"""
module Day15

part1(lines) = map(hashval, split(only(lines), ",")) |> sum

function part2(lines)
  boxes = [Lens[] for _ in 1:256]
  for s in split(only(lines), ",")
    if endswith(s, '-')
      label = chop(s)
      box = hashval(label) + 1
      i = findfirst(l -> l.label == label, boxes[box])
      if i !== nothing
        deleteat!(boxes[box], i)
      end
    else
      (label, power) = split(s, "=")
      box = hashval(label) + 1
      lens = Lens(label, parse(Int, power))
      i = findfirst(l -> l.label == label, boxes[box])
      if i === nothing
        push!(boxes[box], lens)
      else
        boxes[box][i] = lens
      end
    end
  end
  sum(i * j * l.power for (i, lenses) in enumerate(boxes) for (j, l) in enumerate(lenses))
end

struct Lens
  label::AbstractString
  power::Int
end

function hashval(s::AbstractString)
  cur = 0
  for c in s
    cur += Int(c)
    cur *= 17
    cur %= 256
  end
  cur
end

include("../Runner.jl")
@run_if_main
end

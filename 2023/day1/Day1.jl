#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 1
[Read the puzzle](https://adventofcode.com/2023/day/1)

Input is lines with letters and digits, which is extra junk in a two-digit
number, which is the first and last digit in the string.  Output is the sum of
each two-digit number.  In part 2, "one" through "nine" also count as digits.
"""
module Day1

function part1(lines)
  sum(parseinput1(lines))
end

function parseinput1(lines)
  map(lines) do line
    s = filter(isdigit, line)
    # example2 has lines with no ASCII digits, default to zero
    isempty(s) ? 0 : parse(Int, string(first(s), last(s)))
  end
end

function part2(lines)
  sum(parseinput2(lines))
end

function parseinput2(lines)
  words = Dict(map(x -> string(x[2]) => string(x[1]),
    vcat(
      collect(enumerate(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"])),
      collect(enumerate(1:9)))))
  map(lines) do line
    ranges = Iterators.flatten([findall(x, line) for x in keys(words)])
    first = words[line[minimum(ranges)]]
    last = words[line[maximum(ranges)]]
    parse(Int, "$first$last")
  end
end

include("../Runner.jl")
@run_if_main
end

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
  map(lines) do line
    r = replace(line, "one" => "1",
      "two" => "2",
      "three" => "3",
      "four" => "4",
      "five" => "5",
      "six" => "6",
      "seven" => "7",
      "eight" => "8",
      "nine" => "9")
    s = filter(isdigit, r)
    parse(Int, string(first(s), last(s)))
  end
end

include("../Runner.jl")
@run_if_main
end

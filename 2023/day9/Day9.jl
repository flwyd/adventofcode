#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 9
[Read the puzzle](https://adventofcode.com/2023/day/9)

Input is lines of sequences of integers representing readings from a device.  Numbers are spaced
such that repeatedly taking the difference between adjacent numbers eventually results in all
numbers in the reduced list being 0.  Inferring the next (or previous) number consists of finding
the number that will keep the same sequence of reductions to all 0.
Part 1's answer is the sum of next numbers, part 2's answer is the sum of previous numbers.
"""
module Day9

part1(lines) = map(l -> infer(l, +, last), parseinput(lines)) |> sum
part2(lines) = map(l -> infer(l, -, first), parseinput(lines)) |> sum

infer(nums, op, el) =
  allequal(nums) ? nums[1] : op(el(nums), infer(nums[2:end] - nums[1:end-1], op, el))

parseinput(lines) = map(l -> parse.(Int, split(l)), lines) 

include("../Runner.jl")
@run_if_main
end

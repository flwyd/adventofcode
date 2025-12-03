#!/usr/bin/env -S jq -r -R -s -f
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 3
# Read the puzzle at https://adventofcode.com/2025/day/3
# Input is long digit sequences representing 1-digit battery values.
# You can turn on a set of batteries to get joltage (concatenated value).
# In part 1, add the highest possible 2-digit joltages from each line.
# In part 2, add the highest possible 12-digit joltages from each line.

import "runner" as runner;

def part1:
map(split("") | map(tonumber) | to_entries
  | {all: ., first: .[:-1] | max_by(.value * 100000 - .key)}
  | .second = (.all[.first.key+1:] | max_by(.value))
  | .first.value * 10 + .second.value
) | add;

# def badjoltage:
# 100000000000 as $base |
# if length == 12 then join("") | tonumber
# else (.[1:] | joltage) as $recursed | [$recursed, $recursed % $base + .[0] * $base] | max end
# ;
# def bad_part2: map(split("") | map(tonumber) | joltage) | add ;

def removeone: . as $arr | [range(length) | $arr[:.] + $arr[.+1:]];

# TODO can we always remove the first value that's smaller than its successor?
# def removeworst: . as $arr | [range($arr | length) | select($arr[:.] < $arr[.+1:])] | first | $arr[:.] + $arr[.+1:];

def joltage: . as $in |
if $in.rest == [] then .
else {
  best: $in.best | removeone | (map(. + [$in.rest | first]) + [$in.best]) | max,
  # TODO best: $in.best | removeworst | [., $in.best] | max,
  rest: $in.rest[1:]
} | joltage
end;

def part2:
map(split("") | map(tonumber)
  | {best: .[:12], rest: .[12:]} | joltage | .best | join("") | tonumber
) | add;

runner::run(3;  part1;  part2)

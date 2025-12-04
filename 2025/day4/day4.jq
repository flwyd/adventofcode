#!/usr/bin/env -S jq -r -R -s -f
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 4
# Read the puzzle at https://adventofcode.com/2025/day/4
# Input is a grid of . (empty) and @ (obstacle) characters.  An obstacle can be
# moved if there fewer than 4 obstacles in the 8 adjacent spaces; objects at the
# edge can be considered to have empty space "off the grid."
# Part 1 is the number of obstacles that can be removed from the initial state.
# Part 2 is the number of total obstacles that can be removed if you remove each
# obstacle and then look for more removable obstacles.

import "runner" as runner;

def nonnegative($num): [$num, 0] | max;

def removable: . as $lines | $lines | to_entries | map(
  .key as $lnum | .value as $line | range($line | length) as $col
  | [ select($line[$col] == "@") | $lines
    | .[nonnegative($lnum-1):$lnum+2] | map(.[nonnegative($col-1):$col+2])
    | .. | select(. == "@")
  ] | select(length > 0 and length < 5) | {lnum: $lnum, col: $col}
);

def part1: map(split("")) | removable | length;

def part2recurse: . as $in |
(reduce ($in.remove | .[]) as $r ($in.cur; setpath([$r.lnum, $r.col]; "."))) as $next
| {
  total: (.total + ($in.remove | length)),
  cur: $next,
  remove: ($next | removable)
} | if (.remove | length) == 0 then . else part2recurse end;

def part2: {total: 0, cur: map(split("")), remove: []} | part2recurse | .total;

runner::run(4;  part1;  part2)

#!/usr/bin/env -S awk -f
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 7
# Read the puzzle at https://adventofcode.com/2025/day/7
# Input is a grid of characters.  The first line has an S which is where a
# tachyon beam starts, going down the grid.  When a beam reaches a ^ it splits
# in two, with a beam to the left and a beam to the right.
# Part 1: The number of times the beam splits.
# Part 2: The number of possible paths to the bottom of the grid.

function init() { FS=""; part1 = 0; part2 = 0; delete beams; }

function finish() { for (i in beams) { part2 += beams[i] } }

/S/ {
  for (i = 1; i <= NF; i++) { beams[i] = 0; }
  beams[index($0, "S")] = 1;
}

/\^/ {
  for (i in beams) { prev[i] = beams[i]; }
  for (i = 1; i <= NF; i++) {
    if ($i == "^" && prev[i]) {
      part1++;
      beams[i-1] += beams[i];
      beams[i+1] += beams[i];
      beams[i] = 0;
    }
  }
}

BEGIN { DAY = "day7"; init(); }
END { finish(); printf "part1: %s\npart2: %s\n", part1, part2; }

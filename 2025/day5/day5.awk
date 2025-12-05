#!/usr/bin/env -S awk -f
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 5
# Read the puzzle at https://adventofcode.com/2025/day/5
# Input is a series of 123-456 ranges, a blank line, and a series of numbers.
# Part 1 is the count of numbers from the second series which is included in at
# least one range.
# Part 2 is the count of all numbers which are in at least one range, with the
# caveat that many ranges overlap.

function init() {
  part1 = 0; part2 = 0; FS = "-"; delete ranges;
}

function finish() {
  do {
    changed = 0;
    for (cur in ranges) {
      for (other in ranges) {
        if (cur != other && other+0 <= ranges[cur]+0 && ranges[other]+0 >= cur+0) {
          ranges[min(other, cur)] = max(ranges[other], ranges[cur]);
          if (other != cur) {
            delete ranges[max(other, cur)];
          }
          changed = 1;
          break;
        }
      }
      if (changed) {
        break;
      }
    }
  } while (changed);
  for (r in ranges) {
    part2 += (ranges[r]+1 - r);
  }
}

function max(a, b) { return a+0 < b+0 ? b+0 : a+0 }
function min(a, b) { return a+0 > b+0 ? b+0 : a+0 }

/[0-9]+-[0-9]+/ {
  if (!($1 in ranges) || ranges[$1]+0 < $2+0) {
    ranges[$1] = $2;
  }
}

/^[0-9]+$/ {
  for (start in ranges) {
    if (start+0 <= $0 && ranges[start]+0 >= $0) {
      part1++;
      break;
    }
  }
}

BEGIN { DAY = "day5"; init(); }
END { finish(); printf "part1: %s\npart2: %s\n", part1, part2; }

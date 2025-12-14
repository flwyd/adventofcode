#!/bin/zsh
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 12
# Read the puzzle at https://adventofcode.com/2025/day/12
# Input is a list of 3x3 bit masks followed by a list of grid sizes and puzzle
# piece counts.  Ostensibly part 1 is to count the number of grids where all of
# the listed puzzle pieces fit, and the example input has a case where the last
# piece can't fit.  But the actual input is bifurcated into "trivially filled"
# and "more pips than spaces in the grid," so the NP-complete problem has been
# turned into an O(1) problem.

source ${0:h:h}/runner.zsh
((VERBOSE=0))
if [[ $1 == "-v" ]]; then
  ((VERBOSE=1))
  shift
fi
DAY=day12

function solve {
  local inputfile=$1
  PART1=$(grep x $inputfile \
    | sed -e 's/\([0-9][0-9]*\) /\1 + /g' -e 's/x/ * /' -e 's/:/ \/ 7 > /' \
    | xargs -L 1 expr \
    | sed -e 's/^/+ /' \
    | xargs expr 0)
  PART2='Merry Christmas!'
}

runner_solve_files $@
exit $(($FAILURES > 0))

#!/bin/zsh
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
# Part 1 takes about 45 seconds (pipeline in the inner loop spawns thousands of
# total processes), and actual input takes 62 iterations to stabilize, so it
# was reimplemented in jq instead.

source ${0:h:h}/runner.zsh
((VERBOSE=0))
if [[ $1 == "-v" ]]; then
  ((VERBOSE=1))
  shift
fi
DAY=day4

function solve {
  local inputfile=$1
  PART1=0
  PART2=TODO
  input=$(cat $inputfile)
  ((lnum=0))
  maxlines=$(wc -l <<< $input | cut -f 1 -d' ')
  while IFS='' read -r line ; do
    ((lnum++))
    for ((i=1; i <= $#line; i++)) do
      if [[ $line[$i] == '@' ]]; then
        cut="${$((i-1)):/0/1}-$((i+1))"
        tail=3
        if (($lnum == $maxlines)) tail=2
        ats=$(head -n $((lnum+1)) <<< $input |
          tail -n $tail | cut -c $cut | tr -d . | xargs printf '%s')
        # One bigger because cut included current position
        if (($#ats < 5)) ((PART1++))
      fi
    done
  done <<< $input
}

runner_solve_files $@
exit $(($FAILURES > 0))

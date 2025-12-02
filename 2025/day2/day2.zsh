#!/bin/zsh
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 2
# Read the puzzle at https://adventofcode.com/2025/day/2
# Input is a single line of comma-separated ranges like 1234-4567.  In both
# parts, the answer is the sum of invalid numbers in the range.
# Part 1: invalid numbers in base 10 have the first half of the digits repeated
# twice with no intervening (1212 is invalid, 12312 is fine).
# Part 2: invalid numbers are formed from any repeating digit sets: 121212 etc.

source ${0:h:h}/runner.zsh
((VERBOSE=0))
if [[ $1 == "-v" ]]; then
  ((VERBOSE=1))
  shift
fi
DAY=day2

function solve {
  local inputfile=$1
  PART1=0
  PART2=0
  typeset -A found
  IFS=',' read -r -A ranges < $inputfile
  for range in $ranges ; do
    start=${range%-*}
    stop=${range#*-}
    for ((times=2 ; times <= $#stop ; times++)) do
      if (( $#start <= $times )); then
        zeroes=0
      else
        ((zeroes=$#start / $times - 1))
      fi
      chunk=1
      repeat $zeroes chunk+=0
      while (($#chunk * $times <= $#stop)); do
        cur=''
        repeat $times cur+=$chunk
        if (($cur > $stop)); then
          break
        fi
        if [[ ! $found[$cur] ]]; then
          if (($cur >= $start)); then
            ((PART2+=$cur))
            if (($times == 2)); then
              ((PART1+=$cur))
            fi
            found[$cur]=1
          fi
        fi
        ((chunk++))
      done
    done
  done
}

runner_solve_files $@
exit $(($FAILURES > 0))

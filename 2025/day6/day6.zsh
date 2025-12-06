#!/bin/zsh
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 6
# Read the puzzle at https://adventofcode.com/2025/day/6
# Input is space-separated columns of numbers with either + or * at the bottom.
# Numbers in a column don't all have the same number of digits and aren't always
# aligned vertically.
# Part 1: apply the operation at the bottom of each column to all the numbers in
# the column, with numbers read horizontally.
# Part 2: do the same, but numbers are read vertically.

source ${0:h:h}/runner.zsh
((VERBOSE=0))
if [[ $1 == "-v" ]]; then
  ((VERBOSE=1))
  shift
fi
DAY=day6

function solve {
  local inputfile=$1
  PART1=0
  PART2=0
  dcprog='[loxlqx]sp [z1!=p]sq lqx p'
  counts=($(wc $inputfile)) # lines words bytes
  for i in $(seq $(($counts[2]/$counts[1]))); do
    col=$(sed -e 's/^ *//' -e 's/  */\t/g' $inputfile | cut -f $i |
      sed -e '$s/\(.\)/[\1]so '$dcprog'/') <<< $col
    ((PART1+=$(dc <<< $col)))
  done
  ops=$(tail -n 1 $inputfile)
  for ((i = 1; i <= $#ops; )) do
    op=$ops[$i]
    nums=()
    for ((j = $i; ; j++)) do
      num=$(head -n -1 $inputfile | cut -c $j |
        pr -t -s' ' -$counts[1] | sed -e 's/ //g')
      if [[ -n $num ]]; then
        nums+=$num
      else
        ((i=$j + 1))
        break
      fi
    done
    ((PART2+=$(dc <<< "$nums [$op]so $dcprog")))
  done
}

runner_solve_files $@
exit $(($FAILURES > 0))

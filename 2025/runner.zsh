#!/bin/zsh
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Runner functions for Advent of Code zsh solutions.  Scripts should call
# `source ${0:h:h}/runner.zsh` at the start and `runner_solve_files $@` after
# defining a `solve` function which sets $PART1 and $PART2.

# Calls the `solve` function once for each file argument and compares the $PART1
# and $PART2 variables to their expected values.  Any deviations from expected
# values increment $FAILRUES which can be used to set the program exit code.
# If no files are passed to this function, runs `solve` on stdin.  Prints extra
# details to stderr if $VERBOSE is true.  Uses $DAY to print the day number,
# e.g. "Running day13 on input.example.txt"
function runner_solve_files {
  ((FAILURES+=0))
  declare -A EXPECTED
  PART1=""
  PART2=""
  local linecount time_start time_end time_delta
  if (($# == 0)) then
    if (($VERBOSE)) then
      echo "Running $DAY on /dev/stdin:"
    fi
    solve /dev/stdin
    runner_print_results
    if (($VERBOSE)) then
      print -u2 "========================================"
    fi
  else
    for f in $@ ; do
      if [ -f $f ] ; then
        EXPECTED=()
        if (( $VERBOSE )) then
          wc -l $f | read -d ' ' linecount
          print -u2 "Running $DAY on $f ($linecount lines):"
          runner_read_expected $f
        fi
        runner_get_time time_start
        solve $f
        runner_get_time time_end
        ((time_delta=($time_end - $time_start)))
        runner_print_results
        if (( $VERBOSE )) then
          print -u2 "$DAY took $(runner_format_time $time_delta) on $f"
          print -u2 "========================================"
        fi
      else
        print -u2 "File $f does not exist"
      fi
    done
  fi
}

# Sets the provided variable name to the current time in microseconds, e.g.
# runner_get_time start_time ; do_stuff ; runner_get_time end_time
# echo $end_time - $start_time
function runner_get_time {
  # See https://stackoverflow.com/a/59829273
  typeset var captured; captured="$1"; shift
  local oldtimefmt=$TIMEFMT
  TIMEFMT='%uE'
  { read -d us $captured <<<$( { { time ; } 1>&3 ; } 2>&1); } 3>&1
  TIMEFMT=$oldtimefmt
}

# Prints a human-friendly duration given in microseconds.
function runner_format_time {
  local us=$1
  if ((us < 1000)) then
    printf "%dμs\n" us
  elif ((us < 1000000)) then
    printf "%.3fms\n" $((us/1000.0))
  elif ((us < 60000000)) then
    printf "%.3fs\n" $((us/1000000.0))
  else
    printf "%d:%02d\n" $((us/60000000)) $((us%60000000/1000000))
  fi
}

# Read the .expected sibling file of the argument and set $EXPECTED[part1] and
# part2.
function runner_read_expected {
  local file=${1/%.txt/.expected}
  if [[ -e $file ]] then
    while IFS=': ' read part expect ; do
      EXPECTED[$part]=$expect
    done < $file
  fi
}

# Prints $PART1 and $PART2 and, if $VERBOSE, their status relative to their
# expected value.
function runner_print_results {
  echo "part1: $PART1"
  if (($VERBOSE)) then
    runner_print_status $PART1 $EXPECTED[part1]
  fi
  echo "part2: $PART2"
  if (($VERBOSE)) then
    runner_print_status $PART2 $EXPECTED[part2]
  fi
  if [[ -n $EXPECTED[part1] && $PART1 != $EXPECTED[part1] ]]; then
    ((FAILURES++))
  fi
  if [[ -n $EXPECTED[part2] && $PART2 != $EXPECTED[part2] ]]; then
    ((FAILURES++))
  fi
}

# Prints a human-readable status based on actual and expected value.
function runner_print_status {
  local actual=$1
  local expect=$2
  if [[ $actual == $expect ]] then
    print -u2 "✅ SUCCESS got $actual"
  elif [[ $actual == "TODO" ]] then
    if [[ $expect == "" ]] then
      print -u2 "❗ TODO implement it"
    else
      print -u2 "❗ TODO implement it, want $expect"
    fi
  elif [[ $expect != "" ]] then
    print -u2 "❌ FAIL got $actual wanted $expect"
  else
    print -u2 "❓ UNKNOWN got $actual"
  fi
}

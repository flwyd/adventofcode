# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Runner script for AWK solutions for Advent of Code problems.  This runner
# depends on gawk extensions, but solutions themselves may be POSIX-compliant.
# Requires the solution program to have init() and finish() functions which are
# called at the beginning and end of each file, before the runner prints results
# (part1 and part2 variables) and records success or failure.  Solutions should
# also have END { finish(); printf("part1: %s\npart2: %s\n", part1, part2); }
# so they can be run as standalone scripts.

@load "time"

BEGIN {
  runner_active = 1;
  runner_exit_status = 0;
  runner_verbose = 0;
  printf "" > "/dev/stderr"; # otherwise non-verbose warns on close()
}

END {
  close("/dev/stderr");
  exit runner_exit_status;
}

BEGINFILE {
  if (FILENAME == "-v") {
    runner_verbose = 1;
    nextfile;
  }
  if (runner_verbose) {
    printf "Running %s on %s:\n", DAY, FILENAME > "/dev/stderr";
  }
  runner_start = gettimeofday();
  init();
}

ENDFILE {
  finish();
  runner_end = gettimeofday();
  runner_load_expected();
  printf "part1: %s\n", part1; fflush("/dev/stdout");
  if (runner_verbose) {
    runner_print_outcome(part1, runner_expected_values["part1"]);
  }
  printf "part2: %s\n", part2; fflush("/dev/stdout");
  if (runner_verbose) {
    runner_print_outcome(part2, runner_expected_values["part2"]);
    printf "%s took %s on %s\n", DAY,
      runner_format_seconds(runner_end - runner_start), FILENAME > "/dev/stderr";
    print "========================================" > "/dev/stderr";
    fflush("/dev/stderr");
  }
}

function runner_print_outcome(actual, expected) {
  if (actual == expected) {
    printf "✅ SUCCESS got %s\n", actual > "/dev/stderr";
  } else if (actual == "TODO") {
    if (expected == "") {
      printf "❗ TODO implement it\n" > "/dev/stderr";
    } else {
      printf "❗ TODO implement it, want %s\n", expected > "/dev/stderr";
    }
  } else if (expected != "") {
    printf "❌ FAIL got %s wanted %s\n", actual, expected > "/dev/stderr";
    runner_exit_status = 1;
  } else {
    printf "❓ UNKNOWN got %s\n", actual > "/dev/stderr";
  }
  fflush("/dev/stderr");
}

function runner_format_seconds(sec) {
  if (sec < 0.001) {
    return sprintf("%dμs", int(sec * 1000000));
  } else if (sec < 1) {
    return sprintf("%dms", int(sec * 1000));
  } else if (sec < 60) {
    return sprintf("%.3fs", sec);
  } else {
    return sprintf("%d:%02d", int(sec / 60), sec % 60);
  }
}

function runner_load_expected(  k, v, expected_line, expected_file) {
  runner_expected_values["part1"] = "";
  runner_expected_values["part2"] = "";
  expected_file = gensub(/\.txt$/, ".expected", "g", FILENAME);
  while (getline expected_line < expected_file == 1) {
    k = gensub(/(part[0-9]):.*/, "\\1", 1, expected_line);
    v = gensub(/part[0-9]: *(.*)/, "\\1", 1, expected_line);
    runner_expected_values[k] = v;
  }
  close(expected_file);
}

# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code runner functions for R.

read_expected <- function(fname) {
  df <- as.data.frame(strsplit(readLines(fname), ":"))
  names(df) <- df[1, ]
  as.list(lapply(df[-1, ], trimws))
}

run_part <- function(part, lines, expected, fname, verbose = FALSE) {
  name <- as.character(substitute(part))
  if (verbose) {
    log.line(sprintf("Running %s %s on %s (%d lines):",
                     DAY_NAME, name, fname, length(lines)))
  }
  started <- Sys.time()
  answer <- as.character(part(lines))
  finished <- Sys.time()
  write(paste(name, answer, sep = ": "), file = stdout())
  if (verbose) {
    outcome <- list(part = name, got = answer, want = expected)
    log.line(outcome_message(outcome))
    # TODO better duration formatting
    time <- format(difftime(finished, started, units = "secs"))
    log.line(name, "took", time, "on", fname)
    log.line(paste(rep("=", 40), collapse = ""))
  }
  answer == expected || answer == "TODO" || expected == ""
}

run_inputfile <- function(fname, verbose = FALSE) {
  lines <- readLines(fname)
  expfile <- sub("(\\.\\w+)?$", ".expected", fname)
  if (file.exists(expfile)) {
    expected <- read_expected(expfile)
  } else {
    expected <- list(part1 = "", part2 = "")
  }
  p1 <- run_part(part1, lines, expected$part1, fname, verbose = verbose)
  p2 <- run_part(part2, lines, expected$part2, fname, verbose = verbose)
  p1 && p2
}

run_main <- function() {
  status <- TRUE
  verbose <- FALSE
  for (arg in commandArgs(trailingOnly = TRUE)) {
    if (arg == "-v" || arg == "--verbose") {
      verbose <- TRUE
    } else {
      status <- run_inputfile(arg, verbose = verbose) && status
    }
  }
  quit(save = "no", status = if (status) {
    0
  } else {
    1
  })
}

log.line <- function(...) {
  write(paste(...), file = stderr())
}

outcome_message <- function(outcome) {
  if (outcome$got == outcome$want) {
    sprintf("✅ %s got %s", ansi_colored("SUCCESS", "30;102"), outcome$got)
  } else if (outcome$got == "TODO") {
    if (outcome$want == "") {
      sprintf("❗ %s implement it", ansi_colored("TODO", "30;106"))
    } else {
      sprintf("❗ %s implement it, want %s",
              ansi_colored("TODO", "30;106"), outcome$want)
    }
  } else if (outcome$want == "") {
    sprintf("❓ %s got %s", ansi_colored("UNKNOWN", "30;103"), outcome$got)
  } else {
    sprintf("❌ %s got %s, want %s",
            ansi_colored("FAILURE", "30;101"), outcome$got, outcome$want)
  }
}

ansi_colored <- function(word, color) {
  paste("\x1B[", color, "m", word, "\x1B[0m", sep = "")
}

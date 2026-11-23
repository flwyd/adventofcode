#!/usr/bin/env Rscript
# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generates files for an Advent of Code in R.
# Usage: generate.R 2001/day0

template_script <- function(daynum, year, copyyear) {
  gsub("__COPYYEAR__", copyyear,
       gsub("__YEAR__", year,
            gsub("__DAY__", daynum,
'# Copyright __COPYYEAR__ Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code __YEAR__ day __DAY__
# Read the puzzle at https://adventofcode.com/__YEAR__/day/__DAY__

part1 <- function(lines) {
  "TODO"
}

part2 <- function(lines) {
  "TODO"
}

DAY_NAME <- "day__DAY__"')))
}


copyyear <- strftime(Sys.time(), format = "%Y")
for (daydir in commandArgs(TRUE)) {
  if (!file.exists(daydir)) {
    dir.create(daydir)
  }
  daynum <- gsub("\\D", "", basename(daydir))
  year <- basename(dirname(tools::file_path_as_absolute(daydir)))
  rfile <- file.path(daydir, sprintf("day%s.R", daynum))
  if (file.exists(rfile)) {
    write(sprintf("%s already exists, skipping %s",
                  rfile, daydir), file = stderr())
    next
  }
  write(sprintf("Creating files in %s", daydir), file = stderr())
  write(template_script(daynum, year, copyyear), file = rfile)
  extxt <- file.path(daydir, "input.example.txt")
  exexpected <- file.path(daydir, "input.example.expected")
  if (!file.exists(extxt)) {
    file.create(extxt)
  }
  if (!file.exists(exexpected)) {
    writeLines(c("part1: ", "part2: "), con = exexpected)
  }
  for (file in c("input.actual.txt", "input.actual.expected")) {
    path <- file.path(daydir, file)
    target <- sprintf("../input/%s/%s", daynum, file)
    targetrel <- file.path(daydir, target)
    if (!file.exists(path)) {
      if (!file.exists(dirname(targetrel))) {
        dir.create(dirname(targetrel))
      }
      if (!file.exists(targetrel)) {
        file.create(targetrel)
        if (file == "input.actual.expected") {
          writeLines(c("part1: ", "part2: "), con = targetrel)
        }
      }
      file.symlink(target, path)
    }
  }
}

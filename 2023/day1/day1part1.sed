# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2023 day 1 part 1.
# Run with sed -f day1part1.sed input.example.txt | xargs expr

# Replace delete everything between first and last digit and after the last.
s/\([0-9]\).*\([0-9]\).*$/\1\2/
# Replace single-digit lines with that digit repeated.
s/^[^0-9]*\([0-9]\)[^0-9]*$/\1\1/
# Delete any non-leading digits.
s/^[^0-9]*//
# Prepend a + to each line so it can be fed to a calculator.
s/^/+ /

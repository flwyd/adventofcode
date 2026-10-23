# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2023 day 1
# Read the puzzle at https://adventofcode.com/2023/day/1
# Input is a mix of letters and digits which are transformed into 2-digit
# numbers.  In part 1, use the first and last digit, if there's just one digit
# it's repeated.  In part 2, English names of digits also count, and can
# overlap, like "nineight" and "twone".
# This script outputs two-digit numbers prepended by + signs.  To run part 1:
# sed -f day1.sed input.example.txt | xargs expr 0
# For part 2, the input needs to start with "__part2__", so run
# {echo __part2__; cat input.example.txt} | sed -f day1.sed | xargs expr 0

# In part 2, replace digit names while allowing for overlap.
/^__part2__$/,$ {
s/one/o1e/g
s/two/t2o/g
s/three/th3ee/g
s/four/fo4r/g
s/five/fi5e/g
s/six/s6x/g
s/seven/se7en/g
s/eight/ei8ht/g
s/nine/ni9e/g
}
/^__part2__$/d

# Delete everything between first and last digit and after the last.
s/\([0-9]\).*\([0-9]\).*$/\1\2/
# Replace single-digit lines with that digit repeated.
s/^[^0-9]*\([0-9]\)[^0-9]*$/\1\1/
# Delete any non-leading digits.
s/^[^0-9]*//
# If a line has no digits, treat it as 0.
s/^[^0-9]*$/0/
# Prepend a + to each line so it can be fed to a calculator.
s/^/+ /

# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2023 day 1 part 2.
# Run with sed -f day1part2.sed -f day1part1.sed input.example2.txt | xargs expr

# Replace digit names while allowing for overlap.
s/one/o1e/g
s/two/t2o/g
s/three/th3ee/g
s/four/fo4r/g
s/five/fi5e/g
s/six/s6x/g
s/seven/se7en/g
s/eight/ei8ht/g
s/nine/ni9e/g

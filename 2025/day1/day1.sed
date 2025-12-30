#!/usr/bin/env -S sed -f
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 1
# Read the puzzle at https://adventofcode.com/2025/day/1
# A combination lock starts at position 50, numbered 0 to 99.
# Input is like L12 R34 to turn the lock left or right a certain amount.
# In part 1 the answer is the number of turns that end on 0.
# In part 2 it's the number of times the dial passes or lands on 0.
# Feed the output of this sed script to dc.

# Initialize registers a (part1) and b (part2) to 0.  Some dc versions do this
# by default, but macOS Monterey only has GNU dc 1.3.
1i\
0sa 0sb
# Macro z: increment register a (part1). Macro y: increment register b (part2).
# Macro x: make positive by multiplying by -1, run with d0>x for just negatives.
# Macro w: make positive and subtract from 100 for unsigned modular subtraction.
# Macro v/V: if it's not currently at 0 and a left turn would pass 0 (i.e. left
# count is greater than current positive value), increment b.
# Start with lock at 50.
1i\
[la1+sa]sz [lb1+sb]sy [_1*]sx [_1*100r-]sw [r d lrx 0 <Vx]sv [d lRx d lqx !>y]sV
# Macro R: cycle top 3 stack items upward, same as 3R in GNU dc 1.4.
# Macro r: cycle top 3 stack items downward, same as _3R in GNU dc 1.4.
# Macro q: cycle top 4 stack items downward, same as _4R in GNU dc 1.4.
1i\
[S1S2S3L2L1L3]sR [S1S2S3L1L3L2]sr [S1S2S3S4L1L4L3L2]sq
# Macro @: For each lock turn:
# Divide-with-remainder previous and (signed) current value, stash (unsigned)
# remainder, increment a if remainder is zero, increment b by absolute value of
# the integer quotient.
1i\
[100 ~ d d 0 >w lrx 0 =z d 0 >x lb + sb]s@
# Lock starts at 50.
1i\
50
# Left turns subtract, right turns add.  Left turns run macro v.
s/^L\(.*\)/\1 lvx -/
s/^R\(.*\)/\1 +/
a\
l@x
$a\
[part1: ] n la p [part2: ] n lb p

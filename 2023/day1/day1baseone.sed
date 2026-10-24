#!/usr/bin/env sed -n -f
# Copyright 2026 Trevor Stone
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
# This script uses base one character repetition to count the size of the answer
# and then converts to base ten.  To run part 1:
# sed -n -f day1.sed input.example.txt
# For part 2, add an extra instruction to jump to the part2 label:
# sed -n -e 'bpart2' -f day1.sed input.example.txt

# In part 2, replace digit names while allowing for overlap.
# ! makes this block not run, unless the branch function jumps to :part2.
!{
# Useless one-step jump to avoid "unused label" warning in part1.
bpart2
:part2
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

# Delete any non-digits.  Empty lines will be collapsed later.
s/[^0-9]//g
# Delete everything between first and last digit.
s/\([0-9]\).*\([0-9]\)/\1\2/
# Replace single-digit lines with that digit repeated.
s/^[0-9]$/&&/
# Repeat the tens place ten times.
s/^\([0-9]\)/\1\1\1\1\1\1\1\1\1\1/

# Convert digits to base one.
s/9/AAAAAAAAA/g
s/8/AAAAAAAA/g
s/7/AAAAAAA/g
s/6/AAAAAA/g
s/5/AAAAA/g
s/4/AAAA/g
s/3/AAA/g
s/2/AA/g
s/1/A/g
# Append to hold space.  Script needs to be run with -n to avoid printing As.
H

# With everything in base one in the hold space, convert back to base ten.
$ {
# Replace pattern space with hold space.
g
# Join everything into one long line of As.
s/\n//g

# Repeatedly replace ten base one sequences by the next largest letter.
# When this is done the number 1234 is DCCBBAAAA.
# Going up to T supports any 64-bit number, much larger than the actual output.
s/A\{10\}/B/g
s/B\{10\}/C/g
s/C\{10\}/D/g
s/D\{10\}/E/g
s/E\{10\}/F/g
s/F\{10\}/G/g
s/G\{10\}/H/g
s/H\{10\}/I/g
s/I\{10\}/J/g
s/J\{10\}/K/g
s/K\{10\}/L/g
s/L\{10\}/M/g
s/M\{10\}/N/g
s/N\{10\}/O/g
s/O\{10\}/P/g
s/P\{10\}/Q/g
s/Q\{10\}/R/g
s/R\{10\}/S/g
s/S\{10\}/T/g

# Mark base ten digit positions so zero digits can be found.
# 1234 becomes D,CC,BBB,AAA and 2048 becomes DD,,CCCC,AAAAAAAA.
s/^T*/&,/
s/.*,S*/&,/
s/.*,R*/&,/
s/.*,Q*/&,/
s/.*,P*/&,/
s/.*,O*/&,/
s/.*,N*/&,/
s/.*,M*/&,/
s/.*,L*/&,/
s/.*,K*/&,/
s/.*,J*/&,/
s/.*,I*/&,/
s/.*,H*/&,/
s/.*,G*/&,/
s/.*,F*/&,/
s/.*,E*/&,/
s/.*,D*/&,/
s/.*,C*/&,/
s/.*,B*/&,/

# Put zeros in any missing position.  Repeat the ,, substitution because s//
# applies to non-overlapping matches: G,,,,,,A -> G,0,,0,,0,A -> G,0,0,0,0,0,A
s/,$/,0/
s/,,/,0,/g
s/,,/,0,/g

# Convert base one sequences to base ten digits.
s/\([A-Z]\)\1\{8\}/9/g
s/\([A-Z]\)\1\{7\}/8/g
s/\([A-Z]\)\1\{6\}/7/g
s/\([A-Z]\)\1\{5\}/6/g
s/\([A-Z]\)\1\{4\}/5/g
s/\([A-Z]\)\1\{3\}/4/g
s/\([A-Z]\)\1\{2\}/3/g
s/\([A-Z]\)\1/2/g
s/\([A-Z]\)/1/g

# Remove , placeholder and print the base ten number.
s/,//g
s/^0*//
p
}

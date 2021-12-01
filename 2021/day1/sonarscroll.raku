#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Vizualize https://adventofcode.com/2021/day/1 by showing each input line in
# the teriminal with two different boats (Unicode lacks a submaine) and up/down
# or up&down arrows. Part 1 (compare to previous line) is on the left with a
# sailboat, part 2 (compare 3-wide sliding window) is on the right with a ship.
# See output at https://asciinema.org/a/aMgz6qzWyi7OjThb44rsYEB0P
use v6.d;

sub vizualize(@depths, :$delay = 0.1) {
  my $boat1 = "⛵";
  my $boat2 = "🚢";
  my %direction = More => "⬆", Less => "⬇", Same => "⬍";
  my $unknown = "🤷";
  my $linefmt = "%4s %s  %04d %s %-4s";
  put "Part1 ↕ Depth ↕ Part2";
  my $part1 = 0;
  my $part2 = 0;
  for ^@depths -> $i {
    my $dir1 = $i > 0 ?? %direction{@depths[$i] <=> @depths[$i-1]} !! $unknown;
    my $dir2 = $i > 2 ?? %direction{@depths[$i] <=> @depths[$i-3]} !! $unknown;
    $part1++ if $dir1 eq %direction<More>;
    $part2++ if $dir2 eq %direction<More>;
    my $line = sprintf($linefmt, $boat1, $dir1, @depths[$i], $dir2, $boat2);
    print $line;
    sleep $delay;
    print "\c[BACKSPACE]" x $line.chars * 2;
  }
  printf("%5d %s      %s %-5d\n", $part1, %direction<More>, %direction<More>, $part2);
}

sub MAIN(*@input-files) {
  for @input-files -> $file {
    say $file;
    vizualize($file.IO.slurp.lines.map(*.Int));
  }
}

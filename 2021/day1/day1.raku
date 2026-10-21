#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 1
Read the puzzle at L<https://adventofcode.com/2021/day/1>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Day1 does Day {
  has $.input is required;
  has @.input-lines = $!input.lines;

  # Count the number of lines which are greater than the previous one.
  method part1(Str @lines --> Str(Cool)) {
    my $increases = 0;
    my $prev;
    for @lines {
      $increases++ if $prev && $_ > $prev;
      $prev = $_.Int;
    }
    return $increases;
  }

  # Count the number of lines whose 3-line sliding window is in sum larger than
  # the previous line's 3-line sliding window.
  method part2(Str @lines --> Str(Cool)) {
    my $increases = 0;
    for 1..(@lines - 3) -> $i {
      $increases++ if @lines[$i..$i+2].sum > @lines[$i-1..$i+1].sum;
    }
    return $increases;
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day1, @input-files, :$verbose);
}

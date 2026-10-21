#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 6
Read the puzzle at L<https://adventofcode.com/2021/day/6>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Solver {
  has Str $.input is required;
  has $.parsed = $!input.split(',')».Int;

  sub cycle($i) { $i > 0 ?? $i -1 !! 6 }

  method grow-fish($days) {
    my $fish = $.parsed.Bag;
    $fish = ($fish.pairs.map: {cycle(.key) => .value}).Bag ⊎ (8 => +$fish{0},).Bag for ^$days;
    $fish.total;
  }
}

# Fish spawn every 7 days, with 2 extra days when first born.
# How many fish after 80 days?
class Part1 is Solver { method solve( --> Str(Cool)) { self.grow-fish(80) } }

# Same setup, but 256 days.
class Part2 is Solver { method solve( --> Str(Cool)) { self.grow-fish(256) } }

class Day6 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day6, @input-files, :$verbose);
}

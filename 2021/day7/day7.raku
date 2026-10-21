#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 7
Read the puzzle at L<https://adventofcode.com/2021/day/7>
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

  method minimize-fuel(&cost) {
    ([+] $.parsed.map((* - $_).abs).map(&cost) for minmax($.parsed)).min
  }
}

# Minimize the number of steps taken by each crab to move to a single position.
class Part1 is Solver {
  method solve( --> Str(Cool)) { self.minimize-fuel({$_}) }
}

# Now the cost of each step is the number of steps so far.
class Part2 is Solver {
  method solve( --> Str(Cool)) { self.minimize-fuel({$_ * .succ / 2}) }
}

class Day7 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day7, @input-files, :$verbose);
}

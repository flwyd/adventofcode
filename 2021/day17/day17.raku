#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 17
Read the puzzle at L<https://adventofcode.com/2021/day/17>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

grammar InputFormat {
  rule TOP { target area\: x\=<range>\, y\=<range> \n }
  token ws { <!ww>\h* }
  token num { \-?\d+ }
  token range { <num>\.\.<num> }
}

class Actions {
  method TOP($/) { make %{x => $<range>[0].made, y => $<range>[1].made} }
  method num($/) { make $/.Int }
  method range($/) { make Range.new($<num>[0].made, $<num>[1].made) }
}

# Probe fires with initial x,y velocity.  x velocity decreases toward zero by 1
# each step, y velocity decreases by one toward each step.  Hits the target if,
# on any step, the x,y position is in the range provided by the input.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';

  method good-velocities() {
    my $target = $.parsed.made;
    my @maxes;
    for 1..($target<x>.max) -> $initx {
      for ($target<y>.min)..($target<y>.min.abs) -> $inity {
        my $velocity = $initx+i*$inity;
        my $pos = 0+0i;
        my $max = 0;
        while $pos.re ≤ $target<x>.max && $pos.im ≥ $target<y>.min {
          $pos += $velocity;
          $max = max($max, $pos.im);
          $velocity -= $velocity.re.sign + i;
          if $pos.re.Int ~~ $target<x> && $pos.im.Int ~~ $target<y> {
            @maxes.push($max);
            last;
          }
        }
      }
    }
    (@maxes.max, @maxes.elems)
  }
}

# Return the maximum y position on a path that hits the target.
class Part1 is Solver {
  method solve( --> Str(Cool)) { self.good-velocities()[0] }
}

# Return the number of distinct starting velocities that hit the target.
class Part2 is Solver {
  method solve( --> Str(Cool)) { self.good-velocities()[1] }
}

class Day17 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day17, @input-files, :$verbose);
}

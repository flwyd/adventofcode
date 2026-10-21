#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 5
Read the puzzle at L<https://adventofcode.com/2021/day/5>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

sub sequence($a, $b) {
  my $res = minmax($a, $b);
  $res.=reverse if $a > $b;
  $res
}

class Line {
  has $.x1; has $.y1; has $.x2; has $.y2;
  method straight() { $!x1 == $!x2 || $!y1 == $!y2 }
  method points() { sequence($.x1, $.x2) «=>» sequence($.y1, $.y2) }
}

grammar InputFormat {
  rule TOP { <line>+ }
  token num { \d+ }
  rule line { <x=num>\,<y=num> \-\> <x=num>\,<y=num> }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method line($/) {
    make Line.new(:x1($<x>[0].made), :y1($<y>[0].made), :x2($<x>[1].made), :y2($<y>[1].made))
  }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
}

# Count points with at least 2 horizontal or vertical lines intersecting.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my $grid = BagHash.new;
    for $.parsed.made.grep(*.straight) -> $line {
      $grid.add($_) for |$line.points();
    }
    $grid.values.grep(* > 1).elems;
  }
}

# Now include diagonal lines (always a 45° angle) too.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $grid = BagHash.new;
    for $.parsed.made -> $line {
      $grid.add($_) for |$line.points();
    }
    $grid.values.grep(* > 1).elems
  }
}

class Day5 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day5, @input-files, :$verbose);
}

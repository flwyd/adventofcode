#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 13
Read the puzzle at L<https://adventofcode.com/2021/day/13>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

# Input is a series of x,y points with x going left to right and y top to bottom.
# After a blank line, "fold along [xy]=1" lines indicate a series of folds to
# make along row or column of the paper, overlaying points on top of grid spaces.
grammar InputFormat {
  rule TOP { <point> + <fold> + }
  token num { \d+ }
  token point { <num>\,<num> }
  token axis { <[x y]> }
  rule fold { fold along <axis>\=<num> }
}

class Actions {
  method TOP($/) { make (points => $<point>».made, folds => $<fold>».made).Map }
  method num($/) { make $/.Int }
  method point($/) { make "{$<num>[0].made},{$<num>[1].made}" }
  method axis($/) { make $/.Str }
  method fold($/) { make $<axis>.Str => $<num>.Str }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';

  method perform-folds(Set $points is copy, @folds --> Set) {
    for @folds -> $fold {
      $points = $points.keys.map({
        my $p = split-point($_).Hash;
        if $p{$fold.key} > $fold.value {
          $p{$fold.key} = $fold.value - ($p{$fold.key} - $fold.value);
        }
        "{$p<x>},{$p<y>}"
      }).Set;
    }
    $points;
  }
}

sub split-point($p) {
  my @s = $p.split(',');
  (x => @s[0].Int, y => @s[1].Int).Map;
}

# Answer is the number of points on the paper after the first fold.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    self.perform-folds($.parsed.made<points>.Set, $.parsed.made<folds>[0..0]).elems;
  }
}

# Output is ASCII art of the result of all folds, interpreted as capital letters.
# The letters are challenging to read if you swap x and y :-/
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $points = self.perform-folds($.parsed.made<points>.Set, $.parsed.made<folds>);
    my $maxx = $points.keys.map({split-point($_)<x>}).max;
    my $maxy = $points.keys.map({split-point($_)<y>}).max;
    join "\n", gather {
      take "";
      for 0..$maxy -> $y {
        take ("$_,$y" ∈ $points ?? '#' !! '.' for 0..$maxx).join;
      }
    }
  }
}

class Day13 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day13, @input-files, :$verbose);
}

#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 9
Read the puzzle at L<https://adventofcode.com/2021/day/9>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \d }
  rule line { ^^ <num>+ $$ \n }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method line($/) { make $<num>».made }
}

sub neighbors($key) {
  my ($x, $y) = $key.split(',');
  ($x-1, $x, $x, $x+1) »~» <,> »~» ($y, $y-1, $y+1, $y)
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has %.map =
      (given my @g = $!parsed.made { (^@g X ^@g[0]).map(-> ($x, $y) {"$x,$y" => @g[$x;$y]}) });
}

# Find the minima in a grid of 0-9 values. Value is grid number +1, return sum.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    [+] do for %.map.kv -> $k, $v {
      $v + 1 if (%.map{$_}:!exists || $v < %.map{$_} for neighbors($k)).all;
    }
  }
}

# Return the product of the size of the three largest basins, 9s are ridges.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $visited = SetHash.new;
    my @basins = do for %.map.keys -> $first {
      next if $first ∈ $visited;
      my @q = $first;
      my $size = 0;
      while @q.elems > 0 {
        my $key = @q.pop;
        next if $key ∈ $visited;
        $visited.set($key);
        next if %.map{$key} == 9;
        $size++;
        @q.push($_) if %.map{$_}:exists for neighbors($key);
      }
      $size if $size > 0;
    }
    [*] @basins.sort[*-3..*];
  }
}

class Day9 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day9, @input-files, :$verbose);
}

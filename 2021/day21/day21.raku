#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 21
Read the puzzle at L<https://adventofcode.com/2021/day/21>
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
  token num { \d+ }
  rule line { ^^ Player <num> starting position\: <num> $$ \n }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method line($/) { make {player => $<num>[0].made, start => $<num>[1].made } }
}

# Two players are on a loop with spaces 1 through 1.  Take turn rollig a die three
# times, add the sum to their position, add the resulting position to their score.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has @.lines = $!parsed<line>».made;
}

# Deterministic die rolls 1 through 100 in a cycle.  Result is number of rolls
# times the score of the losing player once someone reaches 1000.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my @players = @.lines.map({(player => $_<player>, pos => $_<start>, score => 0).Hash});
    my @rolls = 1..100;
    my $turn = 0;
    my $rollcount = 0;
    while @players.map(*<score>).all < 1000 {
      my $roll = ((++$rollcount - 1) % 100 + 1 for ^3).sum;
      my $pos = (@players[$turn]<pos> - 1 + $roll) % 10 + 1;
      @players[$turn]<score> += $pos;
      @players[$turn]<pos> = $pos;
      $turn = ($turn + 1) % 2;
    }
    # say @players;
    $rollcount * @players.map(*<score>).min
  }
}

# Dirac dice produce a superposition of 1, 2, and 3 each roll.
# Result is the number of times the most-winning player wins.
class Part2 is Solver {
  has %.memo;

  method win-counts($pos, $score, $p1-turn) {
    return 1+0i if $score.re ≥ 21;
    return 0+1i if $score.im ≥ 21;
    my $key = "$pos#$score#$p1-turn";
    return %!memo{$key} if %!memo{$key}:exists;
    my $wins = 0+0i;
    for 1..3 X 1..3 X 1..3 -> $roll {
      my $p;
      my $s = $score;
      if $p1-turn {
        $p = Complex.new(($pos.re + $roll.sum - 1) % 10 + 1, $pos.im);
        $s += $p.re;
      } else {
        $p = Complex.new($pos.re, (($pos.im + $roll.sum - 1) % 10 + 1));
        $s += i*$p.im;
      }
      $wins += self.win-counts($p, $s, !$p1-turn);
    }
    %!memo{$key} = $wins
  }

  method solve( --> Str(Cool)) {
    my $pos = Complex.new(@.lines[0]<start>, @.lines[1]<start>);
    my $wins = self.win-counts($pos, 0+0i, True);
    # say "Win counts: $wins";
    # say "Memoization cached {+%!memo} trees, saving {%!memo.values.map({.re + .im}).sum} wins";
    max($wins.re, $wins.im)
  }
}

class Day21 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day21, @input-files, :$verbose);
}

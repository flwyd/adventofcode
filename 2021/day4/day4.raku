#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 4
Read the puzzle at L<https://adventofcode.com/2021/day/4>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Board {
  has @.nums;
  has @.marked = [[False xx 5] xx 5];

  method mark($num) {
    for (0..^5 X 0..^5) -> ($i, $j) {
      @.marked[$i;$j] = True if @.nums[$i;$j] == $num;
    }
  }

  method done() {
    for 0..^5 -> $i {
      return True if @.marked[$i].grep(so *) == 5;
      return True if @.marked[*;$i].grep(so *) == 5;
    }
    return False;
  }

  method score($num) {
    $num * [+] (for 0..^5 X 0..^5 -> ($i, $j) { @.nums[$i;$j] unless @.marked[$i;$j] })
  }
}

# First line is comma-separated bingo numbers, then 5x5 bingo boards.
grammar InputFormat {
  rule TOP { <numbers> <board>+ }
  token number { \d+ }
  rule numbers { <number>+ % \, }
  rule boardline { <number> ** 5 }
  rule board { <boardline> ** 5 }
}

class Actions {
  method TOP($/) { make {boards => $<board>».made, numbers => $<numbers>.made} }
  method number($/) { make $/.Int }
  method numbers($/) { make $<number>».made }
  method boardline($/) { make $<number>».made }
  method board($/) { make Board.new(nums => $<boardline>».made) }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
}

# Find the first winning bingo board, score is sum of unmarked numbers times
# the number that triggered the win.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my @boards = |$.parsed.made<boards>;
    my @numbers = |$.parsed.made<numbers>;
    for @numbers -> $num {
      @boards».mark($num);
      if @boards.first(*.done) -> $winner {
        return $winner.score($num);
      }
    }
    "no winner after {@numbers}";
  }
}

# Find the last winning bingo board, score as in part 1.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my @boards = |$.parsed.made<boards>;
    my @numbers = |$.parsed.made<numbers>;
    for @numbers -> $num {
      @boards».mark($num);
      if +@boards == 1 && @boards[0].done {
        return @boards[0].score($num);
      }
      @boards.=grep(!*.done);
    }
    "{@boards} left after {@numbers}";
  }
}

class Day4 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day4, @input-files, :$verbose);
}

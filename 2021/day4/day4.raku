#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/4
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $*ERR.say: "Running Day4 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put "part$num: $result";
    $*ERR.printf("Part $num took %.3fms\n", ($end - $start) * 1000);
    @!passed.push($result eq 'TODO' || $expected && $expected eq $result);
    if $expected {
      if $expected eq $result {
        $*ERR.say: "\c[CHECK MARK] PASS with expected value '$result'";
      } else {
        $*ERR.say: "\c[CROSS MARK] FAIL expected '$expected' but got '$result'";
      }
    }
  }
}

sub MAIN(*@input-files) {
  my $exit = all();
  for @input-files -> $input-file {
    if $input-file.IO.slurp -> $input {
      my $context = RunContext.new(:$input, :$input-file);
      if (my $expected-file = $input-file.IO.extension('expected')).f {
        for $expected-file.lines {
          $context.expected«$0» = $1.trim if m/part (\d+) \: \s* (.*)/;
        }
      }
      $context.run-part(Part1);
      $*ERR.say: '';
      $context.run-part(Part2);
      $exit &= all($context.passed);
    } else {
      $*ERR.say: "EMPTY INPUT FILE: $input-file";
    }
    $*ERR.say: '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

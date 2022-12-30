#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/5
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $*ERR.say: "Running Day5 part $num on $!input-file expecting '$expected'";
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

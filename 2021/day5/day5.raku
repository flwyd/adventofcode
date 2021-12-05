#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/5
use v6.d;

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
  token x { \d+ }
  token y { \d+ }
  rule line { <x>\,<y> \-\> <x>\,<y> }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method x($/) { make $/.Int }
  method y($/) { make $/.Int }
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
    my %grid;
    for $.parsed.made.grep(*.straight) -> $line {
      %grid{$_}++ for |$line.points();
    }
    %grid.values.grep(* > 1).elems;
  }
}

# Now include diagonal lines (always a 45° angle) too.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my %grid;
    for $.parsed.made -> $line {
      %grid{$_}++ for |$line.points();
    }
    %grid.values.grep(* > 1).elems
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day5 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put $result;
    "Part $num took %.3fms\n".printf(($end - $start) * 1000);
    if $expected {
      if $expected eq $result {
        say "\c[CHECK MARK] PASS with expected value '$result'";
      } else {
        say "\c[CROSS MARK] FAIL expected '$expected' but got '$result'";
      }
    }
  }
}

sub MAIN(*@input-files) {
  for @input-files -> $input-file {
    if $input-file.IO.slurp -> $input {
      my $context = RunContext.new(:$input, :$input-file);
      if (my $expected-file = $input-file.IO.extension('expected')).f {
        for $expected-file.lines {
          $context.expected«$0» = $1.trim if m/part (\d+) \: \s* (.*)/;
        }
      }
      $context.run-part(Part1);
      say '';
      $context.run-part(Part2);
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
}

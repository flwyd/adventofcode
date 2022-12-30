#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/13
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $expected ~~ s:g/\\n/\n/;
    $*ERR.say: "Running Day13 part $num on $!input-file expecting '$expected'";
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

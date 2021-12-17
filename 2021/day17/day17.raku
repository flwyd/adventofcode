#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/17
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day17 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put $result;
    "Part $num took %.3fms\n".printf(($end - $start) * 1000);
    @!passed.push($result eq 'TODO' || $expected && $expected eq $result);
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
      say '';
      $context.run-part(Part2);
      $exit &= all($context.passed);
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

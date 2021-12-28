#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/3
use v6.d;
use fatal;

grammar InputFormat {
  rule TOP { <line>+ }
  rule line { ^^<[0 1]>+$$ }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method line($/) { make $/.chomp.comb }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';

  method mostly-ones(@nums, $pos) {
    @nums[*;$pos].grep(1) ≥ @nums / 2;
  }
}

# Gamma is binary number taken by combining most common bit in each column.
# Epsilon is binary number taken by combining least common bit in each column.
# Result is their product.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my (@γ, @ε);
    for 0..^$.parsed.made[0].elems -> $col {
      if self.mostly-ones($.parsed.made, $col) {
        @γ.push(1); @ε.push(0);
      } else {
        @γ.push(0); @ε.push(1);
      }
    }
    @γ.join.parse-base(2) * @ε.join.parse-base(2);
  }
}

# For each column, keep the lines which match a particular bit.  Oxygen rating:
# most common bit, preferring 1. CO2 rating: least common bit, preferring 0.
# Result is their product.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my @oxy = $.parsed.made;
    my @co2 = $.parsed.made;
    for 0..^$.parsed.made[0].elems -> $col {
      @oxy.=grep(*[$col] == (self.mostly-ones(@oxy, $col) ?? 1 !! 0)) if @oxy > 1;
      @co2.=grep(*[$col] == (self.mostly-ones(@co2, $col) ?? 0 !! 1)) if @co2 > 1;
    }
    die "Expected 1, not {+@oxy} and {+@co2}" if @oxy != 1 || @co2 != 1;
    [*] (@oxy, @co2).map(*.head.join.parse-base(2));
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
    say "Running Day3 part $num on $!input-file expecting '$expected'";
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

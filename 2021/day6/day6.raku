#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/6
use v6.d;
use fatal;

class Solver {
  has Str $.input is required;
  has $.parsed = $!input.split(',')».Int;

  sub cycle($i) { $i > 0 ?? $i -1 !! 6 }

  method grow-fish($days) {
    my $fish = $.parsed.Bag;
    $fish = ($fish.pairs.map: {cycle(.key) => .value}).Bag ⊎ (8 => +$fish{0},).Bag for ^$days;
    $fish.total;
  }
}

# Fish spawn every 7 days, with 2 extra days when first born.
# How many fish after 80 days?
class Part1 is Solver { method solve( --> Str(Cool)) { self.grow-fish(80) } }

# Same setup, but 256 days.
class Part2 is Solver { method solve( --> Str(Cool)) { self.grow-fish(256) } }

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day6 part $num on $!input-file expecting '$expected'";
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

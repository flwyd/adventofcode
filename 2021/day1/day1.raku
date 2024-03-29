#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/1
use v6.d;
use fatal;

class Day1 {
  has $.input is required;
  has @.input-lines = $!input.lines;

  # Count the number of lines which are greater than the previous one.
  method solve-part1( --> Str(Cool)) {
    my $increases = 0;
    my $prev;
    for @.input-lines {
      $increases++ if $prev && $_ > $prev;
      $prev = $_.Int;
    }
    return $increases;
  }

  # Count the number of lines whose 3-line sliding window is in sum larger than
  # the previous line's 3-line sliding window.
  method solve-part2( --> Str(Cool)) {
    my $increases = 0;
    for 1..(@.input-lines - 3) -> $i {
      $increases++ if @.input-lines[$i..$i+2].sum > @.input-lines[$i-1..$i+1].sum;
    }
    return $increases;
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Int $part) {
    my $expected = $.expected«$part» // '';
    $*ERR.say: "Running Day1 part $part on $!input-file expecting '$expected'";
    my $solver = Day1.new(:$!input);
    my $start = now;
    my $result = $solver."solve-part$part"();
    my $end = now;
    put "part$part: $result";
    $*ERR.printf("Part $part took %.3fms\n", ($end - $start) * 1000);
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
      $context.run-part(1);
      $*ERR.say: '';
      $context.run-part(2);
      $exit &= all($context.passed);
    } else {
      $*ERR.say: "EMPTY INPUT FILE: $input-file";
    }
    $*ERR.say: '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

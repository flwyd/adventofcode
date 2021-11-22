#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/__DAY_NUM__
use v6.d;

grammar InputFormat {
  rule TOP { .* }
}

class FormatActions {
  method TOP($/) { }
}

class __CLASS_NAME__ {
  has $.input is required;
  has @.input-lines = $!input.lines;
  has @.parsed-lines = $!input.lines.map:
      { InputFormat.parse($_, :actions(FormatActions.new)) };

  method solve-part1( --> Str(Cool)) {
    "TODO";
  }

  method solve-part2( --> Str(Cool)) {
    "TODO";
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;

  method run-part(Int $part) {
    my $expected = $.expected«$part» // '';
    say "Running __CLASS_NAME__ part $part on $!input-file expecting '$expected'";
    my $solver = __CLASS_NAME__.new(:$!input);
    my $start = now;
    my $result = $solver."solve-part$part"();
    my $end = now;
    put $result;
    "Part $part took %.3fms\n".printf(($end - $start) * 1000);
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
      $context.run-part(1);
      say '';
      $context.run-part(2);
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
}

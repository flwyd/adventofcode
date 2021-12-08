#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/__DAY_NUM__
use v6.d;
use fatal;

grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \d+ }
  rule line { ^^ .*? $$ \n }
}

class BaseActions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method line($/) { make $/.chomp }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(self.new-actions)) || die 'Parse failed';
  has @.lines = $!parsed<line>;

  submethod new-actions( --> BaseActions) { !!! }
}

class Part1 is Solver {
  class Actions is BaseActions {
  }

  submethod new-actions() { Actions.new }

  method solve( --> Str(Cool)) {
    "TODO";
  }
}

class Part2 is Solver {
  class Actions is BaseActions {
  }

  submethod new-actions() { Actions.new }

  method solve( --> Str(Cool)) {
    "TODO";
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running __CLASS_NAME__ part $num on $!input-file expecting '$expected'";
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

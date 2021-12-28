#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/2
use v6.d;
use fatal;

grammar InputFormat {
  rule TOP { <line>+ }
  token dir { forward || down || up }
  token dist { \d+ }
  rule line { <dir> <dist> }
}

class FormatActions {
  has %.mult = forward => 1+0i, down => 1i, up => -1i;
  has $.part;

  method TOP($/) {
    make $.part == 1 ?? reduce(&infix:<+>, $<line>».made) !! $<line>».made
  }

  method dir($/) { make %!mult{$/.Str} }
  method dist($/) { make $/.Int }
  method line($/) {
    make $.part == 1 ?? $<dir>.made * $<dist>.made !! ($<dir>.Str, $<dist>.Int)
  }

}

class Day2 {
  # TODO change template to do something more clever than passing part to new,
  # maybe make a $*part dynamic variable? Generate a FormatActions base class
  # and empty subclasses for each part? Make each part a separate class?
  has $.part is required;
  has $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(FormatActions.new(:$!part)));
  has @.input-lines = $!input.lines;
  has @.parsed-lines = $!input.lines.map:
      { InputFormat.parse($_, :actions(FormatActions.new(:$!part))) };

  # forward, down, up commands change horizontal and vertical position, return
  # product of final position and depth.  TODO Make a class that stores these
  # fields and can do infix:<+> and <*> rather than (ab)using Complex as a
  # convient "holds two numbers" class.
  method solve-part1( --> Str(Cool)) {
    $.parsed.made.re * $.parsed.made.im
  }

  # down and up commands now change aim value, forward X command moves X
  # horizontally and X * aim down.  TODO Extend the abovementioned class.
  method solve-part2( --> Str(Cool)) {
    my $pos = 0;
    my $depth = 0;
    my $aim = 0;
    for $.parsed.made {
      my ($dir, $dist) = $_;
      given $dir {
        when 'down' { $aim += $dist }
        when 'up' { $aim -= $dist }
        when 'forward' { $pos += $dist; $depth += $aim * $dist }
      }
    }
    $pos * $depth
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Int $part) {
    my $expected = $.expected«$part» // '';
    say "Running Day2 part $part on $!input-file expecting '$expected'";
    my $solver = Day2.new(:$!input, :$part);
    my $start = now;
    my $result = $solver."solve-part$part"();
    my $end = now;
    put $result;
    "Part $part took %.3fms\n".printf(($end - $start) * 1000);
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
      $context.run-part(1);
      say '';
      $context.run-part(2);
      $exit &= all($context.passed);
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

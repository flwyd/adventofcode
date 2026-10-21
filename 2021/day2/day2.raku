#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 2
Read the puzzle at L<https://adventofcode.com/2021/day/2>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

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

class Solver {
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

class Day2 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Solver.new(:input(@lines.join("\n") ~ "\n"), :part(1)).solve-part1();
  }

  method part2(Str @lines --> Str(Cool)) {
    Solver.new(:input(@lines.join("\n") ~ "\n"), :part(2)).solve-part2();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day2, @input-files, :$verbose);
}

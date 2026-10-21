#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 14
Read the puzzle at L<https://adventofcode.com/2021/day/14>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

# Input is a polymer template (series of letters) and then a list of two letters
# an arrow and one letter that is inserted between the two letters when they are
# expanded.
grammar InputFormat {
  rule TOP { <template> \n+ <insertion>+ }
  token ws { <!ww>\h* }
  token template { ^^ \w+ $$ }
  rule insertion { (\w\w) \-\> (\w) \n }
}

class Actions {
  method TOP($/) { make {tmpl => $<template>.made, pairs => $<insertion>».made.Map} }
  method template($/) { make $/.Str }
  method insertion($/) { make ($0.Str => $1.Str) }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
}

# 10 times, insert the appropriate character between each letter pair in the
# string.  Result is the difference of the frequency of the most common and
# least common characters.  This non-optimized implementation generates the
# full string each time.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my $s = $.parsed.made<tmpl>;
    $s = self.transform($s) for ^10;
    my $bag = $s.comb.Bag;
    $bag.values.max - $bag.values.min;
  }

  method transform(Str $s) {
    my $res = '';
    $res ~= $s.substr($_, 1) ~ $.parsed.made<pairs>{$s.substr($_, 2)} for ^($s.chars-1);
    $res ~= $s.substr(*-1);
  }
}

# Now do it 40 times.  Very efficient memoized solution.
class Part2 is Solver {
  has Bag %.memo;

  method solve( --> Str(Cool)) {
    my $tmpl = $.parsed.made<tmpl>;
    my $bag = $tmpl.comb.Bag ⊎ [⊎] (self.counts($_, 40) for $tmpl.comb Z~ $tmpl.substr(1).comb);
    $bag.values.max - $bag.values.min
  }

  method counts($str, $level --> Bag) {
    my $key = "$str,$level";
    return $_ if $_ given %!memo{$key};
    if $level == 1 {
      die "$str at level $level" unless $str.chars == 2;
      return %!memo{$key} = bag($.parsed.made<pairs>{$str});
    }
    my $a = $str.substr(0, 1);
    my $b = $str.substr(1, 1);
    my $mid = $.parsed.made<pairs>{$str};
    return %!memo{$key} =
        self.counts($a ~ $mid, $level - 1) ⊎ self.counts($mid ~ $b, $level - 1) ⊎ $mid;
  }
}

class Day14 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day14, @input-files, :$verbose);
}

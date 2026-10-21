#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 20
Read the puzzle at L<https://adventofcode.com/2021/day/20>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

my @binary-trans = '#' => '1', '.' => '0';

class Solver {
  has Str $.input is required;
  has @.enhancer = $!input.lines[0].trans(@binary-trans).comb;

  method print-image(%image) {
    my $min = %image.keys.min;
    my $max = %image.keys.max;
    for $min.re.Int-1..$max.re.Int+1 -> $row {
      for $min.im.Int-1..$max.im.Int+1 -> $col {
        my $bit = %image{$row+i*$col} // '0';
        print ($bit eq '1' ?? '#' !! '.');
      }
      print "\n";
    }
  }

  method evolve(%image, $horizon) {
    my Str %res{Complex};
    my $min = %image.keys.min;
    my $max = %image.keys.max;
    for $min.re.Int-1..$max.re.Int+1 -> $row {
      for $min.im.Int-1..$max.im.Int+1 -> $col {
        my $points = ($row+i*$col) «+« ((-1, 0, 1) X+ (-1i, 0i, 1i));
        my $pixels = $points.map({%image{$_} // $horizon}).join;
        %res{$row+i*$col} = @.enhancer[$pixels.parse-base(2)];
      }
    }
    %res
  }

  method evolve-steps($steps, :$print = False --> Int) {
    my Str %image{Complex} = $.input.lines[2..*].pairs
        .map(-> $lp { $lp.value.trans(@binary-trans).comb.pairs
            .map({ $lp.key + i*.key => .value })
        }).flat;
    my $horizon = '0';
    for ^$steps {
      %image = self.evolve(%image, $horizon);
      $*ERR.say: "{%image.keys.elems} and {%image.values.sum} 1s points after step $_ with horizon $horizon" if $print;
      $horizon = @.enhancer[$horizon eq '0' ?? 0 !! 511];
      self.print-image(%image) if $print;
    }
    %image.values.sum
  }
}

class Part1 is Solver { method solve( --> Str(Cool)) { self.evolve-steps(2) } }

class Part2 is Solver { method solve( --> Str(Cool)) { self.evolve-steps(50) } }

class Day20 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day20, @input-files, :$verbose);
}

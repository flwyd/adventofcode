#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 22
Read the puzzle at L<https://adventofcode.com/2021/day/22>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Cuboid {
  has Range $.x;
  has Range $.y;
  has Range $.z;
  has Bool $.on;
  has Cuboid @.ignored;

  method Str(Cuboid:D: --> Str) {
    "({$!x.gist},{$!y.gist},{$!z.gist} {$!on ?? 'on' !! 'off'} ignoring {+@!ignored})"
  }

  method size(--> Int) { $!x.elems * $!y.elems * $!z.elems - [+] @!ignored».size }

  method overlaps(Cuboid $other) {
    $!x.min <= $other.x.max && $!x.max >= $other.x.min &&
    $!y.min <= $other.y.max && $!y.max >= $other.y.min &&
    $!z.min <= $other.z.max && $!z.max >= $other.z.min
  }

  method ignore(Cuboid $other) {
    return unless self.overlaps($other);
    .ignore($other) for @!ignored;
    @!ignored .= grep(*.size > 0);
    @!ignored.push($other.clamp(self));
  }

  method clamp(Cuboid $bounds --> Cuboid) {
    my %axes;
    for <x y z> -> $axis {
      my $a = self."$axis"();
      my $b = $bounds."$axis"();
      %axes{$axis} = (max($a.min, $b.min))..(min($a.max, $b.max));
    }
    Cuboid.new(:x(%axes<x>), :y(%axes<y>), :z(%axes<z>), :$!on,
        :ignored(@!ignored.map(*.clamp($bounds))))
  }
}

# Each line is "on|off x=range,y=range,z=range" where range is upper and lower
# integers with .. separators.
grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \-?\d+ }
  token range { <num>\.\.<num> }
  token axis { <[ x y z ]> }
  token switch { on | off }
  rule line { ^^ <switch> (<axis>\=<range>) ** 3..3 % \, $$ \n }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method range($/) { make ($<num>[0].made)..($<num>[1].made) }
  method axis($/) { make $/.Str }
  method switch($/) { make $/.Str }
  method line($/) {
    my %axes = $0.map({$_<axis>.made => $_<range>.made});
    make Cuboid.new(:x(%axes<x>), :y(%axes<y>), :z(%axes<z>), :on($<switch> eq 'on'))
  }
}

# The input defines a sequence of switches in 3D space which are flipped on or off.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has @.lines = $!parsed<line>».made;

  method run-cubes($clamp --> Int) {
    my @on;
    for @.lines -> $line {
      my $clamped = $clamp ?? $line.clamp($clamp) !! $line;
      next if $clamped.size == 0;
      .ignore($clamped) for @on;
      @on .= grep(*.size > 0);
      @on.push($clamped) if $line.on;
    }
    [+] @on».size
  }
}

# Count the number of "on" switches ignoring anything outside the -50..50 ranges.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    self.run-cubes(Cuboid.new(:x(-50..50), :y(-50..50), :z(-50..50), :on));
  }
}

# Count the number of "on" switches everywhere.
class Part2 is Solver {
  method solve( --> Str(Cool)) { self.run-cubes(Nil) }
}

class Day22 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day22, @input-files, :$verbose);
}

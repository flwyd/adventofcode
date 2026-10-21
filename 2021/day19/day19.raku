#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 19
Read the puzzle at L<https://adventofcode.com/2021/day/19>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Point {
  has Int $.x;
  has Int $.y;
  has Int $.z;

  method WHICH(Point:D: --> Str) { self.Str }
  method Str(Point:D: --> Str) { "$!x,$!y,$!z" }

  multi method rotate($axis) {
    do given $axis {
      when 'x' { Point.new(x => $!x, y => -$!z, z => $!y) }
      when 'y' { Point.new(x => $!z, y => $!y, z => -$!x) }
      when 'z' { Point.new(x => -$!y, y => $!x, z => $!z) }
      default { die "Unexpected axis $axis" }
    }
  }

  multi method rotate(Bag $rotation) {
    my $p = Point.new(:$!x, :$!y, :$!z);
    for <x y z> -> $axis {
      for ^$rotation{$axis} {
        $p .= rotate($axis);
      }
    }
    $p
  }

  method plus(Point:D: Point:D \o) { Point.new(:x($!x + o.x), :y($!y + o.y), :z($!z + o.z)) }

  method minus(Point:D: Point:D \o) { Point.new(:x($!x - o.x), :y($!y - o.y), :z($!z - o.z)) }
}

my \Point0 = Point.new(:0x, :0y, :0z);

sub pointcmp(Point:D \a, Point:D \b) { (a.x, a.y, a.z) cmp (b.x, b.y, b.z) }
multi sub infix:<cmp>(Point:D \a, Point:D \b) { pointcmp(a, b) }
multi sub infix:<+>(Point:D \a, Point:D \b) { a.plus(b) }
multi sub infix:<->(Point:D \a, Point:D \b) { a.minus(b) }

class Pointset {
  has Point @.points;
  has Point $.origin;
  has Bag $.rotation;

  method new(@points, Point :$origin = Point.new(:0x, :0y, :0z), Bag :$rotation = bag()) {
    self.bless(:points(@points.sort(&pointcmp)), :$origin, :$rotation)
  }

  method Str(Pointset:D: --> Str) { "Origin $.origin Rotated $.rotation # " ~ @.points.join(' ') }
  method WHICH(Pointset:D: --> Str) { self.Str }

  method x-vals { @.points».x }
  method y-vals { @.points».y }
  method z-vals { @.points».z }
  method vals($axis) {
    do given $axis {
      return self.x-vals when 'x';
      return self.y-vals when 'y';
      return self.z-vals when 'z';
      default { die "Unknown axis $axis" }
    }
  }

  multi method rotate(Str $axis) { Pointset.new(@.points».rotate($axis)) }
  multi method rotate(Bag $rotation) {
    Pointset.new(@.points».rotate($rotation), :origin($.origin.rotate($rotation)), :$rotation)
  }

  method all-orientations( --> List) {
    my @faces = {}.Bag, {:1y}.Bag, {:2y}.Bag, {:3y}.Bag, {:1z}.Bag, {:3z}.Bag;
    my @orientations = {}.Bag, {:1x}.Bag, {:2x}.Bag, {:3x}.Bag;
    (self.rotate($_) for (@orientations X⊎ @faces));
  }

  method offset(Pointset:D: Point:D \p --> Pointset) {
    Pointset.new(@!points.map(* + p), :origin($!origin + p), :$!rotation)
  }

  method overlap(Pointset:D: Pointset:D \them --> Pointset) {
    for @.points X them.points -> ($a, $b) {
      my $aligned = them.offset($a - $b);
      my $match = self.points ∩ $aligned.points;
      return $aligned if $match ≥ 12;
    }
    return Nil;
  }
}

class Scanner {
  has Int $.num;
  has Pointset $.pointset;
  has Pointset @.orientations = $!pointset.all-orientations;

  method Str(Scanner:D:) { "scanner $!num: $!pointset" }
  method WHICH(Scanner:D:) { self.Str }
}

# Input is blocks of "--- scanner # ---", a blank line, and a list of 3D points
# representing beacons from that scanner's (possibly rotated) point of view.
grammar InputFormat {
  rule TOP { <scanner>+ %% \v+ }
  token ws { <!ww>\h* }
  token num { \-?\d+ }
  token point { <num> \, <num> \, <num> }
  rule scanner-head { \-+ scanner <num> \-+ }
  rule scanner { <scanner-head> \v <point>+ % \v }
}

class Actions {
  method TOP($/) { make $<scanner>».made }
  method num($/) { make $/.Int }
  method point($/) { make Point.new(:x($<num>[0].made), :y($<num>[1].made), :z($<num>[2].made)) }
  method scanner-head($/) { make $<num>.made }
  method scanner($/) {
    make Scanner.new(:num($<scanner-head>.made), :pointset(Pointset.new($<point>».made)))
  }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has @.scanners = $!parsed<scanner>».made;

  our %align-cache; # align takes a minute on just 5 scanners, don't bother recomputing

  method align(Solver:D:) {
    return $_ if $_ given %align-cache{$.input};
    my %scanners{Int} = @.scanners.map({$_.num => $_});
    my @all-nums = %scanners.keys.sort;
    my Pointset %found{Int};
    %found{0} = %scanners{0}.pointset;
    my $tried = SetHash.new();
    while %found < @all-nums {
      my $found-this-loop = 0;
      UNFOUND: for @all-nums -> $i {
        next if %found{$i};
        my $target = %scanners{$i};
        for @all-nums -> $j {
          next if $i == $j || !%found{$j};
          next if "$i,$j" ∈ $tried;
          $tried.set("$i,$j");
          my $source = %found{$j};
          for %scanners{$i}.orientations -> $orient {
            my $match = $source.overlap($orient);
            next unless $match;
            %found{$i} = $match;
            $found-this-loop++;
            next UNFOUND;
          }
        }
      }
      $*OUT.flush;
      die "Got stuck, found:\n%found<>" if $found-this-loop == 0;
    }
    %align-cache{$.input} = %found
  }
}

# Count the number of distinct points after aligning all scanners.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my %found = self.align;
    my $points = %found.values».points.Bag;
    $points.elems
  }
}

# Find the maximum Manhattan distance between any two scanners.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my %found = self.align;
    my @origins = %found.values».origin;
    (@origins X- @origins).map({.x.abs + .y.abs + .z.abs}).max
  }
}

class Day19 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day19, @input-files, :$verbose);
}

#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 11
Read the puzzle at L<https://adventofcode.com/2021/day/11>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

# Each iteration, each number in the grid increases by 1.
# Then any number greater than nine which has not flashed yet flashes,
# incrementing all neighbors by one and repeating the flash check.
# Then any > 9 number is reset to 0.
class Solver {
  has Str $.input is required;
  has @.lines = $!input.comb(/\d+/);
  has %.input-grid = (^+@!lines X ^@!lines[0].chars)
      .map(-> ($a, $b) {"$a,$b" => @!lines[$a].substr($b, 1).Int});

  method neighbors($key) {
    my ($x, $y) = $key.split(',');
    (($x-1..$x+1) X ($y-1..$y+1)).grep(-> ($a, $b) { $a ≠ $x || $b ≠ $y})».join(',')
  }

  method increment($grid --> Map) { $grid.pairs.map({ .key => .value + 1 }).Map }

  method flash(Map $grid, SetHash $flashed --> List) {
    my $count = 0;
    my %res = $grid.Hash;
    for $grid.pairs.grep({.value > 9 && .key ∉ $flashed}) -> $p {
      $flashed.set($p.key);
      $count++;
      for self.neighbors($p.key).grep({$grid{$_}:exists}) {
        %res{$_}++;
      }
    }
    %res.Map, $count
  }

  method reset(Map $grid --> Map) { $grid.map({.key => (.value > 9 ?? 0 !! .value)}).Map }
}

# Answer is the count of flashes.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my $grid = %.input-grid.Map;
    my $count = 0;
    for ^100 {
      my $flashed = SetHash.new;
      $grid = self.increment($grid);
      loop {
        ($grid, my $flashes) = self.flash($grid, $flashed);
        $count += $flashes;
        last if $flashes == 0;
      }
      $grid = self.reset($grid);
    }
    $count
  }
}

# Answer is the first 1-based iteration number where all grid positions flashed.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $start = now;
    my $grid = %.input-grid.Map;
    for 1..^∞ -> $i {
      my $flashed = SetHash.new;
      $grid = self.increment($grid);
      loop {
        die "Infinite loop? Ran $i steps" if now - $start > 60;
        ($grid, my $flashes) = self.flash($grid, $flashed);
        return $i if +$flashed == +$grid;
        last if $flashes == 0;
      }
      $grid = self.reset($grid);
    }
  }
}

class Day11 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day11, @input-files, :$verbose);
}

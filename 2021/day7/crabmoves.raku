#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Visualize https://adventofcode.com/2021/day/7 by showing count, direction,
# and distance of crabs moving from each position.
use v6.d;

sub visualize(Bag $positions, &cost, :$delay = 0.1) {
  my $crab = "🦀";
  my $fuel = "⛽";
  my $left = "⬅";
  my $right = "⮕";
  my $stay = "⬇";
  my $allcost = 0;
  my $target = min(minmax($positions.keys), :by(-> $pos {
    $positions.pairs.map({ &cost(abs($_.key - $pos)) * $_.value }).sum;
  }));
  for $positions.pairs.sort {
    my $pos = $_.key;
    my $count = $_.value;
    my $cost = &cost(abs($pos - $target));
    $allcost += $cost * $count;
    my ($before, $dir, $after) = do given $pos {
      when * < $target { ($pos, $right, $target) }
      when * > $target { ($target, $left, $pos) }
      when * == $target { ($pos, $stay, $pos) }
    }
    "%2d $crab %6d $fuel %4d %s %4d\n".printf($count, $cost, $before, $dir, $after);
    sleep $delay;
  }
  say "Total: {$positions.total} $crab  $allcost $fuel  $target $stay";
}

sub MAIN($file, Bool :$gauss = False) {
  say "Moving 🦀s with {$gauss ?? 'expanding' !! 'fixed'} ⛽ cost";
  visualize($file.IO.slurp.comb(/\d+/)».Int.Bag, $gauss ?? {$_ * .succ / 2} !! {$_});
}

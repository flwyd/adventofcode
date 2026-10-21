#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 25
Read the puzzle at L<https://adventofcode.com/2021/day/25>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Solver {
  has Str $.input is required;
  has Complex $.mod;
  has SetHash %.cucumbers is rw = east => SetHash.new, south => SetHash.new;

  submethod TWEAK {
    my $maxre = 0;
    my $maxim = 0;
    for $!input.lines.kv -> $row, $line {
      for $line.comb.kv -> $col, $char {
        given $char {
          when '>' { %!cucumbers<east>.set($row+i*$col) }
          when 'v' { %!cucumbers<south>.set($row+i*$col) }
        }
        $maxim = max($maxim, $col);
      }
      $maxre = $row;
    }
    $!mod = $maxre + 1 + i * ($maxim + 1);
  }

  method next-pos($pos, $dir --> Complex) {
    given $dir {
      when 'east' { $pos.re + i*(($pos.im + 1) % $!mod.im) }
      when 'south' { ($pos.re + 1) % $!mod.re + i*$pos.im }
    }
  }

  method print-grid() {
    for 0..^($!mod.re) -> $row {
      for 0..^($!mod.im) -> $col {
        print(do given $row + i*$col {
          when $_ ∈ %!cucumbers<east> { '>' }
          when $_ ∈ %!cucumbers<south> { 'v' }
          default { '.' }
        });
      }
      print "\n";
    }
  }
}


class Part1 is Solver {
  method solve( --> Str(Cool)) {
    # say "Start size $.mod with {+%.cucumbers<east>} east and {+%.cucumbers<south>} south";
    # self.print-grid;
    for 1..∞ -> $i {
      my SetHash %prev = %.cucumbers;
      %.cucumbers<east> = SetHash.new;
      %.cucumbers<south> = SetHash.new;
      my $changes = 0;
      for %prev<east>.keys {
        my $n = self.next-pos($_, 'east');
        if $n ∈ %prev<east> || $n ∈ %prev<south> {
          %.cucumbers<east>.set($_);
        } else {
          %.cucumbers<east>.set($n);
          $changes++;
        }
      }
      for %prev<south>.keys {
        my $n = self.next-pos($_, 'south');
        # east already moved, check new state
        if $n ∈ %.cucumbers<east> || $n ∈ %prev<south> {
          %.cucumbers<south>.set($_);
        } else {
          %.cucumbers<south>.set($n);
          $changes++;
        }
      }
      # self.print-grid;
      # say "Round $i changed $changes";
      return $i if $changes == 0;
    }
  }
}

class Part2 is Solver { method solve( --> Str(Cool)) { "Merry Christmas"; } }

class Day25 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day25, @input-files, :$verbose);
}

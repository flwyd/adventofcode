#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/25
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $*ERR.say: "Running Day25 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put "part$num: $result";
    $*ERR.printf("Part $num took %.3fms\n", ($end - $start) * 1000);
    @!passed.push($result eq 'TODO' || $expected && $expected eq $result);
    if $expected {
      if $expected eq $result {
        $*ERR.say: "\c[CHECK MARK] PASS with expected value '$result'";
      } else {
        $*ERR.say: "\c[CROSS MARK] FAIL expected '$expected' but got '$result'";
      }
    }
    $*OUT.flush;
    $*ERR.flush;
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
      $context.run-part(Part1);
      $*ERR.say: '';
      $context.run-part(Part2);
      $exit &= all($context.passed);
    } else {
      $*ERR.say: "EMPTY INPUT FILE: $input-file";
    }
    $*ERR.say: '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/9
use v6.d;
use fatal;

grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \d }
  rule line { ^^ <num>+ $$ \n }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method num($/) { make $/.Int }
  method line($/) { make $<num>».made }
}

sub neighbors($key) {
  my ($x, $y) = $key.split(',');
  ($x-1, $x, $x, $x+1) »~» <,> »~» ($y, $y-1, $y+1, $y)
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has %.map =
      (given my @g = $!parsed.made { (^@g X ^@g[0]).map(-> ($x, $y) {"$x,$y" => @g[$x;$y]}) });
}

# Find the minima in a grid of 0-9 values. Value is grid number +1, return sum.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    [+] do for %.map.kv -> $k, $v {
      $v + 1 if (%.map{$_}:!exists || $v < %.map{$_} for neighbors($k)).all;
    }
  }
}

# Return the product of the size of the three largest basins, 9s are ridges.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $visited = SetHash.new;
    my @basins = do for %.map.keys -> $first {
      next if $first ∈ $visited;
      my @q = $first;
      my $size = 0;
      while @q.elems > 0 {
        my $key = @q.pop;
        next if $key ∈ $visited;
        $visited.set($key);
        next if %.map{$key} == 9;
        $size++;
        @q.push($_) if %.map{$_}:exists for neighbors($key);
      }
      $size if $size > 0;
    }
    [*] @basins.sort[*-3..*];
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $*ERR.say: "Running Day9 part $num on $!input-file expecting '$expected'";
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

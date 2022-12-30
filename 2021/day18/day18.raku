#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/18
use v6.d;
use fatal;

# Input is nested pairs with brackets and digits.  Throw away comments and work with a list ints and
# open/close bracket characters.
grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \d+ }
  token bracket { \[ | \] }
  token thing { [ <bracket> | <num> ] \,? }
  token line { <thing>+ \n }
}

class Actions {
  method TOP($/) { make $<line>».made.List }
  method num($/) { make $/.Int }
  method bracket($/) { make $/.Str }
  method thing($/) { make $<bracket>.made || $<num>.made }
  method line($/) { make $<thing>».made.List }
}

sub reduce-pair(*@stuff is copy) {
  REDUCE: loop {
    my $depth = 0;
    my $i = 0;
    EXPLODE: for ^@stuff -> $i {
      given @stuff[$i] {
        when '[' {
          $depth++;
          if $depth > 4 {
            my ($first, $second) = @stuff[$i+1, $i+2];
            die "Not ints after $i $first $second @stuff" unless $first ~~ Int && $second ~~ Int;
            die "Not simple pair $i @stuff[]" unless @stuff[$i+3] eq ']';
            my $j = $i;
            $j-- until $j < 0 || @stuff[$j] ~~ Int;
            # say "Setting $j to @stuff[$j] + $first" unless $j < 0;
            # TODO Why does this sometimes fail with "Cannot assign to an immutable value"?
            # @stuff[$j] += $first unless $j < 0;
            @stuff.splice($j, 1, @stuff[$j] + $first) unless $j < 0;
            $j = $i + 3;
            $j++ until $j ≥ +@stuff || @stuff[$j] ~~ Int;
            # say "Setting $j to @stuff[$j] + $second" unless $j ≥ +@stuff;
            # @stuff[$j] += $second unless $j ≥ +@stuff;
            @stuff.splice($j, 1, @stuff[$j] + $second) unless $j ≥ +@stuff;
            @stuff.splice($i, 4, 0);
            next REDUCE;
          }
        }
        when ']' { $depth-- }
        when Int { }
        default { die "unexpected value $_ in @stuff[]" }
      }
    }
    die "Depth $depth after @stuff" unless $depth == 0;
    SPLIT: for ^@stuff -> $i {
      if @stuff[$i] ~~ Int && @stuff[$i] ≥ 10 {
        @stuff.splice($i, 1, ('[', .floor, .ceiling, ']')) given @stuff[$i]/2;
        next REDUCE;
      }
    }
    last REDUCE;
  }
  @stuff
}

sub add-pair($a, $b) { reduce-pair(('[', |$a, |$b, ']')).cache }

sub magnitude(@pair) {
  my @nums;
  for @pair {
    given $_ {
      when Int { @nums.push($_) };
      when '[' { }
      when ']' { @nums.push((@nums.splice(*-2) Z* (3, 2)).sum) } # 3, 2 are specified in the problem
      default { die "unexpected value $_ in @pair[]" };
    }
  }
  die "Nums remainder: @nums[] from @pair[]" unless +@nums == 1;
  @nums[0]
}

# Pairs must be reduced using explode and split operations, applying the leftmost explode until
# there are no more explodes, then the leftmost split until there are no more splits.  Explodes
# happen to any pair that's nested in four other pairs.  Splits happen to any int ≥ 10.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has @.lines = $!parsed<line>».made;
}

# Add (wrap in a pair) all lines in the input, then determine the recursive magnitude:
# 3 * first value + 2 * second value.
class Part1 is Solver { method solve( --> Str(Cool)) { magnitude(@.lines.reduce: &add-pair) } }

# Determine the maximum magnitude of adding any two pairs in the input, noting that addition is
# not commutative.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    (^@.lines X ^@.lines).grep({.head != .tail})
        .map({magnitude(add-pair(@.lines[.head], $.lines[.tail]))})
        .max
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
    $*ERR.say: "Running Day18 part $num on $!input-file expecting '$expected'";
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

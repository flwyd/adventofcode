#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/8
use v6.d;
use fatal;

# Input is series of words made up of a..g characters. Each character is an
# active segment in a seven-segment display, and each word represents a digit.
# There are ten words, a pipe, and four words.  The first set are the wiring
# permutations for all 10 digits, the last four represent a number.
grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token digit { \w+ }
  rule digits { <digit> + }
  rule line { <digits> \| <digits> \n}
}

class Actions {
  method TOP($/) { make $<line>».made }
  method line($/) { make %{ first => $<digits>[0].made, second => $<digits>[1].made } }
  method digit($/) { make $/.Str }
  method digits($/) { make $<digit>».made }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die "Parse failed";
}

# Count the number of unique digits (length 2, 3, 4, 7) in the 4-digit numbers.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    [+] ($_<second>.grep(so *.chars == 2|3|4|7).elems for $.parsed.made)
  }
}

# Sum all of the 4-digit numbers.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $allopts = set('a'..'g');
    my $sum = 0;
    # Segments for each digit 0-9 with correct wiring
    my @segments = (<a b c e f g>, <c f>, <a c d e g>, <a c d f g>, <b c d f>,
        <a b d f g>, <a b d e f g>, <a c f>, <a b c d e f g>, <a b c d f g>);
    # Look up a digit by the sorted set of segments
    my %byname = @segments.pairs.map: { .value.sort.join => .key };
    # Digits (values) with a unique number of segments (key)
    my %uniques = %byname.map({ .key.chars => .value })
        .classify(*.key, :as{.value})
        .grep(*.value.elems == 1)
        .map({.key => .value.head});
    # Which segments are possible matches for "missing" characters, by number of segments
    my %holes = %byname.keys.grep(*.chars < 7)
        .map({ .chars => $allopts ∖ .comb })
        .categorize(*.key, :as{|.value})
        .map({.key => [∪] .value});
    for $.parsed.made -> $line {
      # Each letter starts unconstrained
      my %possible = ($_ => $allopts for 'a'..'g');
      # Constrain based on letters found in the unique-segment-count digits
      for %uniques.kv -> $k, $v {
        for $line<first>.grep(*.chars == $k) -> $digit {
          my @chars = $digit.comb;
          %possible{$_} ∩= @segments[$v] for @chars;
          %possible{$_} ∖= @segments[$v] for ($allopts ∖ @chars).keys;
        }
      }
      # Constrain based on missing segments from any digit
      for %holes.kv -> $k, $v {
        for $line<first>.grep(*.chars == $k) -> $digit {
          my @missing = ($allopts ∖ $digit.comb).keys;
          %possible{$_} ∩= $v for @missing;
        }
      }
      # Constrain by removing letters that already have a unique assignment
      my @determined = %possible.values.grep(*.elems == 1)».keys.flat;
      for %possible.kv -> $k, $v {
        %possible{$k} ∖= @determined if $v.elems > 1;
      }
      die "Non-unique chars from $line\n{%possible}" unless all(%possible.values.map(*.elems)) == 1;
      # Transform miswired segments into 4-digit numbers
      $sum += $line<second>.map({ %byname{%possible{.comb}.map(*.pick).sort.join} }).join;
    }
    return $sum;
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
    say "Running Day8 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put $result;
    "Part $num took %.3fms\n".printf(($end - $start) * 1000);
    @!passed.push($result eq 'TODO' || $expected && $expected eq $result);
    if $expected {
      if $expected eq $result {
        say "\c[CHECK MARK] PASS with expected value '$result'";
      } else {
        say "\c[CROSS MARK] FAIL expected '$expected' but got '$result'";
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
      say '';
      $context.run-part(Part2);
      $exit &= all($context.passed);
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

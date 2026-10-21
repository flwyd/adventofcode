#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 10
Read the puzzle at L<https://adventofcode.com/2021/day/10>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

class Solver {
  has Str $.input is required;
  has @.lines = $!input.trans('<>' => '⟨⟩').comb(/\V+/);
}

# Sum of scores for the first closing punctuation that doesn't match its opener.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my %scores = <) 3 ] 57 } 1197 ⟩ 25137>;
    my $score = 0;
    for @.lines -> $line {
      my @stack;
      for $line.comb -> $char {
        given $char.uniprop('General_Category') {
          when 'Ps' { @stack.push($char.uniprop('Bidi_Mirroring_Glyph')) }
          when 'Pe' {
            if @stack[*-1] ne $char {
              $score += %scores{$char};
              last;
            } else { @stack.pop }
          }
          default { die "Unexpected $char category $_" }
        }
      }
    }
    $score
  }
}

# Median score of lines with incomplete balanced punctuation.  Score is based
# on left-to-right order of dangling open punctuation.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my %scores = <) 1 ] 2 } 3 ⟩ 4>;
    my @scores;
    LINE: for @.lines -> $line {
      my @stack;
      for $line.comb -> $char {
        given $char.uniprop('General_Category') {
          when 'Ps' { @stack.push($char.uniprop('Bidi_Mirroring_Glyph')) }
          when 'Pe' {
            next LINE if @stack[*-1] ne $char;
            @stack.pop;
          }
          default { die "Unexpected $char category $_" }
        }
      }
      @scores.push((0, |@stack.reverse.map({%scores{$_}})).reduce({$^r * 5 + $^s}));
    }
    @scores.sort[*/2]
  }
}

class Day10 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day10, @input-files, :$verbose);
}

#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/10
use v6.d;
use fatal;

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

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day10 part $num on $!input-file expecting '$expected'";
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

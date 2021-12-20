#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/20
use v6.d;
use fatal;

my @binary-trans = '#' => '1', '.' => '0';

class Solver {
  has Str $.input is required;
  has @.enhancer = $!input.lines[0].trans(@binary-trans).comb;

  method print-image(%image) {
    my $min = %image.keys.min;
    my $max = %image.keys.max;
    for $min.re.Int-1..$max.re.Int+1 -> $row {
      for $min.im.Int-1..$max.im.Int+1 -> $col {
        my $bit = %image{$row+i*$col} // '0';
        print ($bit eq '1' ?? '#' !! '.');
      }
      print "\n";
    }
  }

  method evolve(%image, $horizon) {
    my Str %res{Complex};
    my $min = %image.keys.min;
    my $max = %image.keys.max;
    for $min.re.Int-1..$max.re.Int+1 -> $row {
      for $min.im.Int-1..$max.im.Int+1 -> $col {
        my $points = ($row+i*$col) «+« ((-1, 0, 1) X+ (-1i, 0i, 1i));
        my $pixels = $points.map({%image{$_} // $horizon}).join;
        %res{$row+i*$col} = @.enhancer[$pixels.parse-base(2)];
      }
    }
    %res
  }

  method evolve-steps($steps, :$print = False --> Int) {
    my Str %image{Complex} = $.input.lines[2..*].pairs
        .map(-> $lp { $lp.value.trans(@binary-trans).comb.pairs
            .map({ $lp.key + i*.key => .value })
        }).flat;
    my $horizon = '0';
    for ^$steps {
      %image = self.evolve(%image, $horizon);
      say "{%image.keys.elems} and {%image.values.sum} 1s points after step $_ with horizon $horizon" if $print;
      $horizon = @.enhancer[$horizon eq '0' ?? 0 !! 511];
      self.print-image(%image) if $print;
    }
    %image.values.sum
  }
}

class Part1 is Solver { method solve( --> Str(Cool)) { self.evolve-steps(2) } }

class Part2 is Solver { method solve( --> Str(Cool)) { self.evolve-steps(50) } }

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day20 part $num on $!input-file expecting '$expected'";
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

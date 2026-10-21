#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 16
Read the puzzle at L<https://adventofcode.com/2021/day/16>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

# Input is a hexadecimal string representing a variable-length binary encoding
# of a stack-based math expression.
class Solver {
  has Str $.input is required;
  has @.binary = $!input.chomp.parse-base(16).base(2).comb;

  submethod TWEAK { @!binary.prepend(0 xx $!input.chomp.chars * 4 - +@!binary) }

  method parse-and-eval( --> List) {
    my $version-sum = 0;
    my @states = 'version';
    my @ops;
    my @values;
    while ?@states {
      given @states.pop {
        when 'version' {
          $version-sum += @.binary.splice(0, 3).join.parse-base(2);
          @states.push('type');
        }
        when 'type' {
          given @.binary.splice(0, 3).join.parse-base(2) {
            when 4 { @states.push('literal') }
            default { @states.push("operator:$_") }
          }
        }
        when 'literal' {
          @values.push((gather loop {
            my ($first, @rest) = @.binary.splice(0, 5);
            take @rest.join;
            last if $first == 0;
          }).join.parse-base(2));
        }
        when /operator\:(\d+)/ {
          @states.push("eval:{+@values}");
          @ops.push: do given $0 {
            when 0 { &infix:«+» }
            when 1 { &infix:«*» }
            when 2 { &min }
            when 3 { &max }
            when 5 { &infix:«>» }
            when 6 { &infix:«<» }
            when 7 { &infix:«==» }
            default { die "Unknown operator type $0" }
          }
          given @.binary.shift {
            when 0 { @states.push('length-bits') }
            when 1 { @states.push('length-packets') }
            default { die "Not binary $_" }
          }
        }
        when /eval\:(\d+)/ { @values.push(+@values.splice($0.Int).reduce(@ops.pop)) }
        when /length\-bits/ {
          @states.push("packetbits:$_") given @.binary.splice(0, 15).join.parse-base(2);
        }
        when /length\-packets/ {
          @states.push("packets:$_") given @.binary.splice(0, 11).join.parse-base(2);
        }
        when /packetbits\:(\d+)/ { @states.push("remainingbits:{+@.binary-$0}", 'version'); }
        when /remainingbits\:(\d+)/ {
          given $0 <=> +@.binary { # do nothing on Same
            when Less { @states.push($/.Str, 'version') }
            when More { die "Expected $0 remaining packet bits, only {+@.binary} left" }
          }
        }
        when /packets\:(\d+)/ {
          @states.push("packets:{$0-1}") if $0 > 1;
          @states.push('version');
        }
        default { die "Can't handle state $_" }
      }
    }
    die "Leftover bits: (@.binary[])" if @.binary > 0 && @.binary.any() != 0;
    die "Leftover ops: @ops[] values: @values[]" if @ops > 0 || @values != 1;
    $($version-sum, @values[0])
  }
}

# The first three bytes of each packet are a version number, return the sum.
class Part1 is Solver { method solve( --> Str(Cool)) { self.parse-and-eval()[0] } }

# Evaluate the whole shebang, version numbers don't matter.
class Part2 is Solver { method solve( --> Str(Cool)) { self.parse-and-eval()[1] } }

class Day16 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day16, @input-files, :$verbose);
}

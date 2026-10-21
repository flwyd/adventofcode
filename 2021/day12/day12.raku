#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#

=begin pod
=head1 Advent of Code 2021 day 12
Read the puzzle at L<https://adventofcode.com/2021/day/12>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('../../lang/raku').resolve;
}
use Runner;

grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token word { \w+ }
  rule line { ^^ <word>\-<word> $$ \n }
}

class Actions {
  method TOP($/) { make $<line>».made }
  method word($/) { make $/.Str }
  method line($/) { make $<word>[0].made => $<word>[1].made }
}

sub big($name) { $name ~~ /^<:Lu>+$/ }
sub small($name) { $name eq none('start', 'end') && $name ~~ /^<:Ll>+$/ }

# Input is an undirected graph with nodes separated by hyphen.  Upper case are
# "big rooms", lower case are "small rooms", start and end are special.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has Array %.graph = $!parsed.made.map({$_, .antipair}).flat.classify(*.value, :as(*.key));
  has Bag $.default-budget =
      (%!graph.keys.map: { when &big { $_ => 1000 }; default { $_ => 1 } }).Bag;
  has Int %.dfsmemo; # keyed by the whole budget to catch all small room variants
  has Int $.memosaved = 0;

  method dfs(Str $to, Str $from, Bag $budget --> Int) {
    return 1 if $from eq $to;
    my $key = "$from:{$budget.sort.join('@')}";
    if (my $memo = %.dfsmemo{$key}) && $memo.defined {
      $!memosaved += $memo;
      return $memo;
    }
    my $new-budget = self.new-budget($budget, $from);
    my $revisitable = '_revisit' ∈ $new-budget;
    my $res = [+] do for %.graph{$from}.grep({$_ ∈ $new-budget || $revisitable && small($_)}) {
      self.dfs($to, $_, $new-budget)
    }
    $.dfsmemo{$key} = $res;
    $res;
  }

  submethod new-budget(Bag $budget, Str $cur --> Bag) { ??? }
}

# Count the paths from start to end; each small room can only traverse once.
class Part1 is Solver {
  method solve( --> Str(Cool)) { self.dfs('end', 'start', $.default-budget); }

  submethod new-budget(Bag $budget, Str $cur --> Bag) { $budget ∖ $cur }
}

# Count the paths from start to end; at most one small room can be used twice.
class Part2 is Solver {
  method solve( --> Str(Cool)) { self.dfs('end', 'start', $.default-budget ⊎ (_revisit => 1)); }

  submethod new-budget(Bag $budget, Str $cur --> Bag) {
    return $budget ∖ '_revisit' if small($cur) && $cur ∉ $budget && '_revisit' ∈ $budget;
    return $budget ∖ $cur;
  }
}

class Day12 does Day {
  method part1(Str @lines --> Str(Cool)) {
    Part1.new(:input(@lines.join("\n") ~ "\n")).solve();
  }

  method part2(Str @lines --> Str(Cool)) {
    Part2.new(:input(@lines.join("\n") ~ "\n")).solve();
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day12, @input-files, :$verbose);
}

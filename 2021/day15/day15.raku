#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/15
use v6.d;
use fatal;

class Solver {
  has Str $.input is required;
  has Str $.algorithm = 'dijkstra';
  has %.grid{Complex} = self.make-grid($!input);
  has $.target = %!grid.keys.max;

  submethod make-grid($input) { ??? }

  method solve( --> Str(Cool)) {
    given $.algorithm {
      when "dijkstra" { self.dijkstra-cost }
      when "astar" { self.astar-cost }
      default { die "Unknown algorithm $.algorithm" }
    }
  }

  method dijkstra-cost( --> Int) {
    my Array %options{Int};
    %options{0}.push(0+0i);
    my $visited = SetHash.new(0+0i);
    my $min = %options.keys.min;
    while so %options {
      unless %options{$min} {
        %options{$min}:delete;
        $min = %options.keys.min;
        redo;
      }
      my $cur = %options{$min}.pop; # race on all options at this cost actually makes things slower
      return $min if $cur == $.target;
      for self.neighbors($cur, $visited) {
        unless $_ ∈ $visited {
          %options{$min + %.grid{$_}}.push($_);
          $visited.set($_);
        }
      }
    }
    fail "ran out of options";
  }

  # TODO figure out why A* implementation is slower and gets the wrong answer
  method heuristic(Complex $pos --> Int(Num)) { ($.target.re - $pos.re) + ($.target.im - $pos.im) }
  method astar-cost( --> Int) {
    my Array %options{Int};
    %options{0}.append(${pos => 0+0i, cost => 0});
    my $visited = SetHash.new(0+0i);
    while so %options {
      my $min = %options.keys.min;
      unless %options{$min} {
        %options{$min}:delete;
        $min = %options.keys.min;
        redo;
      }
      my $cur = %options{$min}.pop;
      return $cur<cost> if $cur<pos> == $.target;
      for self.neighbors($cur<pos>, $visited) {
        unless $_ ∈ $visited {
          my $cost = $cur<cost> + %.grid{$_};
          my $x = (pos => $_, cost => $cost).Map;
          %options{$cost + self.heuristic($_)}.append($x);
          $visited.set($_);
        }
      }
    }
    fail "ran out of options";
  }

  method neighbors(Complex $pos, Setty $visited --> Seq) {
    my $choices = []; # this imperative style is a little faster than gather/take
    $choices.push($pos+1) if $pos.re < $.target.re;
    $choices.push($pos+1i) if $pos.im < $.target.im;
    # Don't move backwards if we get to the edge.  This optimization wasn't a huge win.
    $choices.push($pos-1i) if 0 < $pos.re < $.target.re && $pos.im > 0;
    $choices.push($pos-1) if 0 < $pos.im < $.target.im && $pos.re > 0;
    $choices.grep({$_ ∉ $visited})
  }
}


class Part1 is Solver {
  submethod make-grid($input) {
    $input.lines.pairs.map(
      -> $r { $r.value.comb.pairs.map(
        -> $c { Pair.new($r.key+$c.key*i, $c.value.Int) })}
    ).flat
  }
}

class Part2 is Solver {
  submethod make-grid($input) {
    my %h{Complex} = $input.lines.pairs.map(
      -> $r { $r.value.comb.pairs.map(
        -> $c { Pair.new($r.key+$c.key*i, $c.value.Int) })}
    ).flat;
    my $size = %h.keys.max.re + 1;
    for 1..4 -> $i {
      for 0..^$size -> $r {
        for 0..^$size -> $c {
          %h{$r+($c+$i*$size)*i} = %h{$r+($c+($i-1)*$size)*i} mod 9 + 1;
        }
      }
    }
    for 1..4 -> $j {
      for 0..^$size -> $r {
        for 0..^($size*5) -> $c {
          %h{($r+$j*$size)+$c*i} = %h{($r+($j-1)*$size)+$c*i} mod 9 + 1;
        }
      }
    }
    %h
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;
  has $.algorithm;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day15 part $num with $!algorithm on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input, :$!algorithm);
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

sub MAIN(*@input-files, :$algorithm = "dijkstra") {
  my $exit = all();
  for @input-files -> $input-file {
    if $input-file.IO.slurp -> $input {
      my $context = RunContext.new(:$input, :$input-file, :$algorithm);
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

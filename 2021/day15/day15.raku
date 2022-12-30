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
  has Str $.algorithm = 'astar';
  has %.grid{Complex} = self.make-grid($!input);
  has Complex $.target = self.identify-target(%!grid); # %!grid.keys.max;

  submethod make-grid($input) { ??? }
  submethod identify-target($grid) { ??? }
  method cost-at($point) { ??? }

  method solve( --> Str(Cool)) {
    given $.algorithm {
      when "dijkstra" { self.dijkstra-cost }
      when "astar" { self.astar-cost }
      when "meetme" { self.meetme-cost }
      default { die "Unknown algorithm $.algorithm" }
    }
  }

  method dijkstra-cost( --> Int) {
    # my Array %options{Int};
    # %options{0}.push(0+0i);
    my Array @options;
    @options[0].push(0+0i);
    my $visited = SetHash.new(0+0i);
    # my $min = %options.keys.min;
    my $min = 0;
    # while so %options {
    while so @options {
      $min++ until @options[$min];
      # unless %options{$min} {
      #   %options{$min}:delete;
      #   $min = %options.keys.min;
      #   redo;
      # }
      # my $cur = %options{$min}.pop; # race on all options at this cost actually makes things slower
      my $cur = @options[$min].pop;
      return $min if $cur == $.target;
      for self.neighbors($cur) {
        unless $_ ∈ $visited {
          # %options{$min + %.grid{$_}}.push($_);
          # @options[$min + %.grid{$_}].push($_);
          @options[$min + self.cost-at($_)].push($_);
          $visited.set($_);
        }
      }
    }
    fail "ran out of options";
  }

  method meetme-cost( --> Int) {
    my %cost is default((∞, ∞));
    # say "Cost: |{%cost<foo>}|";
    %cost{0+0i} = (0, ∞);
    # say "Target is $.target";
    %cost{$.target} = (∞, self.cost-at($.target));
    my Array @options;
    @options[0].push((0+0i, 0));
    # say "Appending $.target";
    @options[self.cost-at($.target)].push(($.target, 1));
    # @options[0].push((0+0i, 0));
    # @options[self.cost-at($.target)].push(($.target, 1));
    # my $visited = SetHash.new(0+0i);
    my $min = 0;
    while ?@options {
      $min++ until @options[$min];
      my $cur = @options[$min].pop;
      say "Investigating ($cur), cost $min";
      return $_ if $_ < ∞ given %cost{$cur[0]}.sum;
      # say "Neighbors for $cur";
      # return $min if $cur == $.target;
      for self.neighbors($cur[0]) {
        # unless $_ ∈ $visited {
        # say "Cost of $_: |{%cost{$_}}|";
        if $min < %cost{$_}[$cur[1]] {
          # %options{$min + %.grid{$_}}.push($_);
          # @options[$min + %.grid{$_}].push($_);
          # say "new neighbor $_";
          my $thiscost = $min + self.cost-at($_);
          @options[$thiscost].push(($_, $cur[1]));
          my $curcost = %cost{$_};
          my $newcost = do given $cur[1] {
            when 0 { ($thiscost, $curcost[1]) }
            when 1 { ($curcost[0], $thiscost) }
            default { die "Expected 0 or 1 in ($cur)" }
          }
          return $newcost.sum if $newcost[0] < ∞ && $newcost[1] < ∞;
          %cost{$_} = $newcost;
          # $visited.set($_);
        }
      }
    }
    fail "ran out of options";
  }

  # TODO figure out why A* implementation is slower and gets the wrong answer
  method heuristic(Complex $pos --> Int(Num)) { ($.target.re - $pos.re) + ($.target.im - $pos.im) }
  method astar-cost( --> Int) {
    # my Array %options{Int};
    my Array @options;
    # %options{self.heuristic(0+0i)}.push(${pos => 0+0i, cost => 0});
    @options[self.heuristic(0+0i)].push(${pos => 0+0i, cost => 0});
    my $visited = SetHash.new(0+0i);
    # my $min = %options.keys.min;
    my $min = 0;
    # while so %options {
    while so @options {
      $min++ until @options[$min];
      # unless %options{$min} {
      #   %options{$min}:delete;
      #   $min = %options.keys.min;
      #   redo;
      # }
      # my $cur = %options{$min}.pop;
      my $cur = @options[$min].pop;
      return $cur<cost> if $cur<pos> == $.target;
      for self.neighbors($cur<pos>) {
        unless $_ ∈ $visited {
          # my $cost = $cur<cost> + %.grid{$_};
          my $cost = $cur<cost> + self.cost-at($_);
          my $x = (pos => $_, cost => $cost).Map;
          # %options{$cost + self.heuristic($_)}.push($x);
          die "got infinite cost from $cur" if $cost == ∞;
          @options[$cost + self.heuristic($_)].push($x);
          $visited.set($_);
        }
      }
    }
    fail "ran out of options";
  }

  method neighbors($pos) {
    ($pos+1, $pos+1i, $pos-1, $pos-1i).grep({self.cost-at($_) < ∞})
  }
  method old-neighbors($pos) {
    my $choices = []; # this imperative style is a little faster than gather/take
    $choices.push($pos+1) if $pos.re < $.target.re;
    $choices.push($pos+1i) if $pos.im < $.target.im;
    # Don't move backwards if we get to the edge.  This optimization wasn't a huge win.
    $choices.push($pos-1i) if 0 < $pos.re < $.target.re && $pos.im > 0;
    $choices.push($pos-1) if 0 < $pos.im < $.target.im && $pos.re > 0;
    # $choices.grep({$_ ∉ $visited})
    $choices
  }
}


class Part1 is Solver {
  submethod make-grid($input) {
    $input.lines.pairs.map(
      -> $r { $r.value.comb.pairs.map(
        -> $c { Pair.new($r.key+$c.key*i, $c.value.Int) })}
    ).flat
  }

  submethod identify-target($grid) { $grid.keys.max }

  method cost-at($point) { $.grid{$point} // ∞ }
}

class Part2 is Solver {
  has $.grid-max;

  submethod identify-target($grid) {
    $!grid-max = $grid.keys.max;
  }
  submethod fancy-identify-target($grid) {
    $!grid-max = $grid.keys.max;
    return $_ + ($_ + 1+1i) * 4 given $grid.keys.max
  }

  method cost-at($point) { $.grid{$point} // ∞ }
  method fancy-cost-at($point) {
    return %.grid{$point} if %.grid{$point}:exists;
    return ∞ if $point.re < 0 || $point.im < 0 || $point.re > $.target.re || $point.im > $.target.im;
    my \px = $point.re.Int;
    my \py = $point.im.Int;
    my \tx = $.grid-max.re.Int + 1;
    my \ty = $.grid-max.im.Int + 1;
    # my ($px, $py) = $point.reals.map(*.Int);
    # my ($tx, $ty) = $.grid-max.reals.map(*.Int + 1);
    # say "p ($px,$py) t ($tx,$ty)";
    my \dist = px div tx + py div ty;
    # say "point $point target $.target";
    my \base = (px mod tx) + (py mod ty)i;
    # my $cur = %.grid{$base};
    # say "$point -> $base, $cur + $dist = {($cur + $dist - 1) % 9 + 1}";
    return (%.grid{base} + dist - 1) % 9 + 1;
  }

  submethod fancy-make-grid($input) {
    $input.lines.pairs.map(
      -> $r { $r.value.comb.pairs.map(
        -> $c { Pair.new($r.key+$c.key*i, $c.value.Int) })}
    ).flat
  }
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
    my $make-time = now;
    my $result = $solver.solve();
    my $end = now;
    put $result;
    "Part $num took %.3fms\n".printf(($end - $start) * 1000);
    "Construction took %.3fms solve took %.3fms\n".printf(($make-time - $start) * 1000, ($end - $make-time) * 1000);
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

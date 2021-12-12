#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/12
use v6.d;
use fatal;

grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token word { \w+ }
  rule line { ^^ <word>\-<word> $$ \n }
}

class Actions {
  method TOP($/) { say "Parsed {$<line>.elems} lines"; make $<line>».made }
  method word($/) { make $/.Str }
  method line($/) { make $<word>[0].made => $<word>[1].made }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
  has @.lines = $!parsed<line>».made;
}

class Part1 is Solver {
  method dfs(%g, $vs, $vb, $x --> Int) {
    # say "'$x' small $vs big $vb";
    # say %g{$x};
    return 0 unless $x;
    given $x {
      when 'end' { return 1 }
      when /^<[a..z]>+/ {
        # say "small '$x'";
        return 0 unless %g{$x};
        return 0 if $x (elem) $vs;
        return [+] (self.dfs(%g, $vs (^) $x, $vb, $_) for |%g{$x});
      }
      when /^<[A..Z]>+/ {
        # say "big '$x'";
        return 0 unless %g{$x};
        # my $p = "$vb#$x";
        # return 0 if $x (elem) $vb;
        my $c = 0;
        for |%g{$x} {
          my $p = "$x#$_";
          $c += self.dfs(%g, $vs, $vb (^) $p, $_) unless $p (elem) $vb;
        }
        return $c;
        # return [+] dfs(%g, $vs, $vb (^) $p, $x) for |%g{$x};
      }
      default { die "wtf '$x'" }
    }
  }

  method solve( --> Str(Cool)) {
    my %g ;
    for |$.parsed.made -> $p {
      %g{$p.key} //= [];
      %g{$p.key}.push: $p.value;
      %g{$p.value} //= [];
      %g{$p.value}.push: $p.key;
    }
    self.dfs(%g, Set.new, Set.new, 'start');
  }
}

class Part2 is Solver {
  method dfs(%g, Set $vs, Set $vb, Str $small, Str $seen, Str $x --> List) {
    return 0 unless $x;
    my $seen2 = $seen eq '' ?? $x !! "$seen,$x";
    given $x {
      when 'end' { return ($seen2,) }
      when /^<[a..z]>+/ {
        return () unless %g{$x};
        return () if $x (elem) $vs && ($small ne '' || $x eq 'start');
        my $small2 = $x (elem) $vs ?? $x !! $small;
        return (self.dfs(%g, $vs (^) $x, $vb, $small2, $seen2, $_) if $_ ne $small for |%g{$x}).flat.List;
      }
      when /^<[A..Z]>+/ {
        return 0 unless %g{$x};
        return (self.dfs(%g, $vs, $vb , $small, $seen2, $_) if $_ ne $small for |%g{$x}).flat.List;
      }
      default { die "wtf '$x'" }
    }
  }

  method valid(Str $res --> Bool) {
    $res ne '' && $res.split(',').Bag.pairs.grep({.key ~~ /^<[a..z]>+$/ && .value > 1}).elems <= 1
  }

  method solve( --> Str(Cool)) {
    my %g ;
    for |$.parsed.made -> $p {
      %g{$p.key} //= [];
      %g{$p.key}.push: $p.value;
      %g{$p.value} //= [];
      %g{$p.value}.push: $p.key;
    }
    my $res = self.dfs(%g, Set.new, Set.new, '', '', 'start').Set.keys.List;
    # say "Before filter {+$res}";
    # say $res.sort.join("\n");
    $res .= grep({self.valid($_)});
    # say "After filter {+$res}";
    # say $res.sort.join("\n");
    $res.elems
  }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    say "Running Day12 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put $result;
    "Part $num took %.3fms\n".printf(($end - $start) * 1000);
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
    } else {
      say "EMPTY INPUT FILE: $input-file";
    }
    say '=' x 40;
  }
}

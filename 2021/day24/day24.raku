#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/24
use v6.d;
use fatal;

# This Raku program "cheats" by using a magic suffix (for part 1) or a magic
# infix (for part 2) found by the day24.go program.  The (not optimized)
# implementation of the MONAD ALU in Raku runs very slowly, and was only able
# to check about 20 million numbers per day on my old computer.  Even
# constraining to searching six digits takes over 20 minutes for part 2 (which
# needs to cover more than half of the input space given my input).

class ModelNumber {
  has Int @.digits;

  method new(Int $val) {
    my @digits = $val.base(9).comb »+» (1,);
    @digits.unshift(1) while +@digits < 14;
    die "Got @digits[], not 14" unless +@digits == 14;
    self.bless(:@digits)
  }

  method digit(Int $i) { die "$i too big" unless $i < @!digits; @!digits[$i] }
  method Str(ModelNumber:D:) { @.digits.join }
}

class ProgramState {
  has Int %.registers = :0w, :0x, :0y, :0z;
  has ModelNumber $.input is required;
  has Int $.index = 0;

  method get-register(Str $reg --> Int) { %!registers{$reg} }
  method set-register(Str $reg, Int $val) { %!registers{$reg} = $val }
  method next-input() { $!input.digit($!index++) }
  method Str(ProgramState:D:) {
    <w x y z>.map({"$_=>%.registers{$_}"}).join(', ')
        ~ ' input: ' ~ $.input.digits.join
        ~ " index: $.index"
  }
}

class Operand {
  has Str $.type;
  has Cool $.val;

  method eval(ProgramState $state --> Int) { $!type eq 'num' ?? $!val !! $state.get-register($!val) }
  method Str(Operand:D:) { $.val.Str }
}

class Operation {
  has Str $.op is required;
  has Operand $.a is required;
  has Operand $.b;

  submethod TWEAK { die "operand b not set for $!op $!a" unless $!b.defined || $!op eq 'inp' }

  method eval(ProgramState $state) {
    $state.set-register($!a.val, do given $!op {
      when 'inp' { $state.next-input }
      when 'add' { $!a.eval($state) + $!b.eval($state) }
      when 'mul' { $!a.eval($state) * $!b.eval($state) }
      when 'div' { floor($!a.eval($state) / $!b.eval($state)) }
      when 'mod' { $!a.eval($state) % $!b.eval($state) }
      when 'eql' { +($!a.eval($state) == $!b.eval($state)) }
    })
  }

  method Str(Operation:D:) { "$.op $.a" ~ (" $.b" if $.b.defined) }
}

class Program {
  has Operation @.operations;
  has Bool $.verbose = False;

  method eval(ModelNumber $input --> ProgramState) {
    my $state = ProgramState.new(:$input);
    for @.operations {
      $_.eval($state);
      say "$_ ~ $state" if $!verbose;
    }
    $state
  }

  method Str(Program:D:) { @.operations.join("\n") }
}

# Input is a series of inp(ut), add, mul(tiply), div(ide), mod, and eql (1 if equal, 0 if not)
# operations on registers w, x, y, or z and either another register or a fixed integer value;
# the result of the operation is written back to the first register.  Unary inp operations read
# the next input digit in the range of 1 to 9.  14-digit input numbers are valid if z=0 at the end.
grammar InputFormat {
  rule TOP { <line>+ }
  token ws { <!ww>\h* }
  token num { \-?\d+ }
  token var { <[ w x y z ]> }
  token op { inp | add | mul | div | mod | eql }
  token operand { <var> | <num> }
  rule unary { <op> <var> }
  rule binary { <op> <operand> <operand> }
  rule line { [ <binary> | <unary> ] \n }
}

class Actions {
  method TOP($/) { make Program.new(:operations($<line>».made)) }
  method num($/) { make Operand.new(type => 'num', val => $/.Int) }
  method var($/) { make Operand.new(type => 'var', val => $/.Str) }
  method op($/) { make $/.Str }
  method operand($/) { make ($<var> || $<num>).made }
  method unary($/) {
    die unless $<op>.made eq 'inp';
    make Operation.new(:op($<op>.made), :a($<var>.made))
  }
  method binary($/) {
    make Operation.new(:op($<op>.made), :a($<operand>[0].made), :b($<operand>[1].made))
  }
  method line($/) { make ($<unary> || $<binary>).made }
}

class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse($!input, :actions(Actions.new)) || die 'Parse failed';
}

# Result is the largest number that has z=0 at the end of the program.
class Part1 is Solver {
  method solve( --> Str(Cool)) {
    my $prog = $.parsed.made;
    my $magic-suffix = '82088762'; # subtract one from digits '93199873' found by Go
    my $all-nines-prefix = ('8' x 14 - $magic-suffix.chars);
    loop (my $i = $all-nines-prefix.parse-base(9); $i > 0; $i--) {
      my $num = ($i.base(9) ~ $magic-suffix).parse-base(9);
      my $model = ModelNumber.new($num);
      my $state = $prog.eval($model);
      if $state.get-register('z') == 0 {
        say "Found z=0 for $model == $num";
        return $model.Str;
      }
    }
    say "Didn't find any matches between $all-nines-prefix$magic-suffix and 0$magic-suffix";
    0
  }

  # I originally tried solving by doing a "ratcheting binary search" on the
  # assumption that valid inputs would be reasonably common.  (It turns out
  # that my input has at least 6 numbers that satisfy the program, but possibly
  # not more than that.)  That produced no matches, so I tried randomly
  # guessing 14-digit numbers to see if I could get *any* hit I could learn
  # something from.  That ran for six days without finding any valid numbers.
  # It's left here as an homage to attempts at elegant solutions before I
  # started fresh in Go and pegged 10 CPUs with a divide-and-conquer approach
  # on a beefy machine for hours.
  method old-solve( --> Str(Cool)) {
    my $prog = $.parsed.made;
    my $all-nines = ('8' x 14).parse-base(9);
    my $max = 0;
    my $max-model = ModelNumber.new(0);
    my $all-tried = SetHash.new();
    my $tried-count = 0;
    my $last-tried = $all-nines;
    my $last-gap = $all-nines;
    my $last-high = $all-nines;
    while $all-nines - $max > 10_000_000 && $tried-count < $all-nines - $max {
      my $try = ($max^..$all-nines).pick;
      my $num = ModelNumber.new($try);
      my $state = $prog.eval($num);
      if $state.get-register('z') == 0 {
        say "$num ($try) is valid: $state";
        $max = $try;
        $max-model = $num;
        $tried-count = 0;
        next;
      }
      say "Tried $tried-count" if ++$tried-count %% 1000;
    }
    say "Highwater mark is $max-model ($max)";
    for $max^..$all-nines {
      my $num = ModelNumber.new($_);
      my $state = $prog.eval($num);
      if $state.get-register('z') == 0 {
        $max = $_;
        $max-model = $num;
      }
    }
    say "Max is $max, $max-model";
    return $max-model.Str;
    # The ratcheting binary search approach:
    # say "Program on 1s:";
    # say $prog.eval(ModelNumber.new(0));
    # say "Program on 9s:";
    # say $prog.eval(ModelNumber.new($all-nines));
    # RATCHET: loop {
    #   loop (my $high = $all-nines; $last-gap > 1; $high = $last-tried) {
    #     my $mid = $max + floor(($high - $max)/2);
    #     my $num = ModelNumber.new($mid);
    #     my $state = $prog.eval($num);
    #     $last-gap = $last-tried - $mid;
    #     say "High $high max: $max mid: $mid z: {$state.get-register('z')} num: $num gap $last-gap";
    #     if $state.get-register('z') == 0 {
    #       $max = $mid;
    #       $max-model = $num;
    #       say "$mid is valid: $state";
    #       next RATCHET;
    #     }
    #     $last-tried = $mid;
    #   }
    #   say "loop end last-tried $last-tried max $max model $max-model";
    #   last if $all-nines - $last-tried < 3;
    # }
    # return $max;
  }
}

# Result is the smallest number that has z=0 at the end of the program.
class Part2 is Solver {
  method solve( --> Str(Cool)) {
    my $prog = $.parsed.made;
    my $magic-infix = '81221197'.comb.map(*-1).join; # based on Go output
    for '111'..'999' -> $i {
      for '111'..'999' -> $j {
        my $num = ($i.comb.map(*-1).join ~ $magic-infix ~ $j.comb.map(*-1).join).parse-base(9);
        my $model = ModelNumber.new($num);
        my $state = $prog.eval($model);
        if $state.get-register('z') == 0 {
          say "Found z=0 for $model == $num";
          return $model.Str;
        }
      }
    }
    say "Didn't find any matches between 111{$magic-infix}111 and 999{$magic-infix}999";
    0
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
    say "Running Day24 part $num on $!input-file expecting '$expected'";
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
    $*OUT.flush;
    $*ERR.flush;
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

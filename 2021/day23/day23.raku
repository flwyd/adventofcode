#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2021/day/23
use v6.d;
use fatal;

class Position {
  has Int $.hall = 0;
  has Int $.room = 0;
  has Int $.room-slot = 0;

  method WHICH(Position:D:) { ValueObjAt.new("Position|{$!hall + $!room}/$!room-slot") }

  method Str(Position:D:) {
    return "hall:$!hall" if $.hall;
    return "room:$!room/$!room-slot";
  }

  method x(Position:D: --> Int) { $!room || $!hall }

  method dist(Position:D: Position:D $other --> Int) {
    return abs($.x - $other.x) + $.room-slot + $other.room-slot;
  }

  method in-way(Position:D: Position:D $dest, Position:D $other --> Bool) {
    return min($.x, $dest.x) ≤ $other.hall ≤ max($.x, $dest.x) if $other.hall > 0;
    return False if $other.room != $!room && $other.room != $dest.room;
    return $other.room-slot < $!room-slot if $other.room == $!room;
    return $other.room-slot < $dest.room-slot;
  }
}

class Amphipod {
  has Str $.type;
  has Position $.pos;
  has Int $.target-room;
  has $.step-cost = 10 ** ($!type.ord - 'A'.ord);
  has $!which-cache = ValueObjAt.new("Amphipod|$!type:$!pos");

  method WHICH(Amphipod:D:) { $!which-cache }

  method Str(Amphipod:D:) { "<$.type wants $.target-room currently $.pos>" }

  method satisfied { $!target-room == $!pos.room }

  method move-cost(Position $dest --> Int) { $!step-cost * $.pos.dist($dest) }

  method move(Position $dest --> Amphipod) {
    Amphipod.new(:$!type, :pos($dest), :$!target-room, :$!step-cost)
  }
}

class Board {
  has Int $.hall-length;
  has Amphipod @.pods;
  has Int @.room-nums = @!pods.map({.pos.room}).sort.unique;
  has Int $.depth = @!pods.map(*.pos.room-slot).max;
  has Int $.cost = 0;
  has Board @.parents;
  has $!which-cache = ValueObjAt.new("Board|" ~ @!pods».WHICH.sort.join(';'));

  method WHICH(Board:D:) { $!which-cache }

  method Str(Board:D:) { "Board($.hall-length @.pods[])" }

  method ascii(Board:D: --> Str) {
    my @p = @.pods.sort({
      $^a.pos.room == $^b.pos.room ?? $a.pos.room-slot <=> $b.pos.room-slot !! $a.pos.room <=> $b.pos.room
    });
    my @res;
    @res.push('#' x $.hall-length + 2);
    my @hall = '#', |('.' xx $.hall-length), '#';
    @hall[.pos.hall] = .type for @.pods.grep(*.pos.hall > 0);
    @res.push(@hall.join);
    for 1..$!depth -> $i {
      my @line = '#' xx $.hall-length + 2;
      if $i > 1 {
        @line[$_] = ' ' for 0..^(@.room-nums[0]-1);
        @line[$_] = ' ' for (@.room-nums[*-1]+2)..($.hall-length+2);
      }
      @line[$_] = '.' for @.room-nums;
      @line[.pos.room] = .type for @.pods.grep(*.pos.room-slot == $i);
      @res.push(@line.join);
    }
    @res.push("{' ' x @.room-nums[0] - 1}{'#' x +@.room-nums * 2 + 1}");
    @res.join("\n");
  }

  method satisfied( --> Bool) { so @!pods.all.satisfied }

  method valid-moves() {
    my @res;
    my @in-hall = @.pods.grep(*.pos.hall > 0);
    my %in-rooms = @.pods.grep(*.pos.room > 0).classify(*.pos.room);
    for @in-hall -> $pod {
      my @in-slot = |(%in-rooms{$pod.target-room} // ());
      next unless @in-slot < $!depth;
      next if @in-slot.grep(*.type ne $pod.type);
      my $dest = Position.new(:room($pod.target-room), :room-slot($!depth - @in-slot));
      next if @in-hall.grep({$_ !eqv $pod && $pod.pos.in-way($dest, $_.pos)});
      @res.push((self.move($pod, $dest), $pod.move-cost($dest)));
    }
    for %in-rooms.kv -> $room, $pods {
      my @p = $pods.sort({$^a.pos.room-slot <=> $^b.pos.room-slot});
      next if @p.all.target-room == $room;
      my $pod = @p[0];
      my @in-slot = |(%in-rooms{$pod.target-room} // ());
      if @in-slot.all.type eq $pod.type {
        my $dest = Position.new(:room($pod.target-room), :room-slot($!depth - @in-slot));
        my $hall-ok = True; # any junction does unnecessary work, so do it manually
        for @in-hall {
          if $pod.pos.in-way($dest, .pos) {
            $hall-ok = False;
            last;
          }
        }
        @res.push((self.move($pod, $dest), $pod.move-cost($dest))) if $hall-ok;
      }
      HALL: for 1..$.hall-length {
        next if @.room-nums.grep($_);
        my $dest = Position.new(:hall($_));
        next HALL if $pod.pos.in-way($dest, $_.pos) for @in-hall;
        @res.push((self.move($pod, $dest), $pod.move-cost($dest)));
      }
    }
    @res
  }

  method move(Amphipod $pod, Position $dest --> Board) {
    my $moved = $pod.move($dest);
    Board.new(:$.hall-length, :@.room-nums, :pods(@.pods.map({$_ eqv $pod ?? $moved !! $_})),
        :cost($.cost + $pod.move-cost($dest)), :parents(|@.parents, self), :$.depth)
  }

  method min-remaining-cost( --> Int) {
    my $res = 0;
    my %types = @.pods.classify(*.type);
    for %types.kv -> $type, $pods {
      my $target = $!depth;
      $target-- while $pods.grep({.target-room == .pos.room && .pos.room-slot == $target});
      for $pods.grep({.target-room != .pos.room || .pos.room-slot < $target}) {
        $res += .move-cost(Position.new(:room(.target-room), :room-slot($target--)));
      }
    }
    $res
  }
}

# Input is ASCII art of a horizontal hallway with attached vertical rooms of
# two amphipods.  Part 2 adds two more rows of amphipods in the middle.
grammar InputFormat {
  token TOP { <allwall> <hall> <rooms>+ <allwall> }
  token ws { <!ww>\h* }
  token wall { '#' }
  token dot { '.' }
  token pod { <[ A B C D ]> }
  token allwall { \h* <wall>+ \h* \n }
  token hall { <wall> <dot>+ <wall> \n }
  token rooms { \h* <wall>+ <pod> ** 4 % <wall> <wall>+ \h* \n }
}

class Actions {
  has $!last-slot = 0;
  method TOP($/) {
    make {length => $<hall>.made, rooms => gather for $<rooms>».made -> $l { .take for |$l } }
  }
  method hall($/) { make $<dot>.elems }
  method rooms($/) {
    my $room-slot = ++$!last-slot;
    my @targets = $<pod>.map({.from - $/.from});
    make $<pod>.map({
      Amphipod.new(:type(.Str),
        :pos(Position.new(:room(.from - $/.from), :$room-slot)),
        :target-room(@targets[.Str.ord - 'A'.ord]))
    }).flat.Array
  }
}

# Each amphipod (identified by a letter) has a move cost per space:
# A=1, B=10, C=100, D=1000.  Solution is cheapest cost to move each amphipod to
# their appropriate room, which are in alphabetic order.
class Solver {
  has Str $.input is required;
  has $.parsed = InputFormat.parse(self.modify-input($!input), :actions(Actions.new)) || die 'Parse failed';
  has $.hall-length = $!parsed.made<length>;
  has @.pods = $!parsed.made<rooms>.map({.Array}).flat;
  has @.room-nums = @!pods.map({.pos.room}).sort.unique;

  submethod modify-input($input --> Str) { $input }

  method cheapest-solution( --> Int) {
    my $initial = Board.new(:$.hall-length, :@.pods, :@.room-nums);
    $*ERR.say: $initial.ascii;
    my Array @q;
    @q[0].push($initial);
    my $min = 0;
    my $last-said = -1;
    my $last-noted = 0;
    my %seen = $initial => 0;
    my $dupes = 0;
    my $total-size = 1;
    my $too-expensive = 0;
    while @q {
      $min++ until @q[$min];
      my $board = @q[$min].shift;
      if $min - $last-noted >= 500 {
        $*ERR.say: "Min: $min size: $total-size dupes: $dupes of {+%seen}";
        $last-noted = $min;
      }
      --$total-size;
      $last-said = $min;
      if $board.satisfied {
        $*ERR.say: "Found winning board at min: $min size: $total-size dupes: $dupes of {+%seen}";
        # say "Winning board at $min: $board from\n{$board.parents».ascii.join(qq|\n\n|)}";
        # say "\n" ~ $board.ascii;
        return $board.cost;
      }
      for $board.valid-moves {
        my ($next, $cost) = |$_;
        if (%seen{$next} // ∞) <= $next.cost {
          ++$dupes;
        } else {
          %seen{$next} = $next.cost;
          @q[$next.cost + $next.min-remaining-cost].push($next);
          ++$total-size;
        }
      }
    }
    die "Empty queue";
  }
}

class Part1 is Solver {
  submethod modify-input($input --> Str) { $input }

  method solve( --> Str(Cool)) { self.cheapest-solution() }
}

# Part 2 adds two extra lines in the middle of the rooms part of the board.
class Part2 is Solver {
  submethod modify-input($input --> Str) {
    my @lines = $input.lines;
    @lines.splice(3, 0, '  #D#C#B#A#', '  #D#B#A#C#');
    @lines.join("\n") ~ "\n"
  }

  method solve( --> Str(Cool)) { self.cheapest-solution() }
}

class RunContext {
  has $.input-file;
  has $.input;
  has %.expected is rw;
  has @.passed;

  method run-part(Solver:U $part) {
    my $num = $part.^name.comb(/\d+/).head;
    my $expected = $.expected«$num» // '';
    $*ERR.say: "Running Day23 part $num on $!input-file expecting '$expected'";
    my $start = now;
    my $solver = $part.new(:$!input);
    my $result = $solver.solve();
    my $end = now;
    put "part$num: $result";
    $*ERR.printf("Part $num took %.3fms\n", ($end - $start) * 1000);
    @!passed.push($result eq 'TODO' || $expected && $expected eq $result);
    if $expected {
      if $expected eq $result {
        $*ERR.say: "\c[CHECK MARK] PASS with expected value '$result'";
      } else {
        $*ERR.say: "\c[CROSS MARK] FAIL expected '$expected' but got '$result'";
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
      $*ERR.say: '';
      $context.run-part(Part2);
      $exit &= all($context.passed);
    } else {
      $*ERR.say: "EMPTY INPUT FILE: $input-file";
    }
    $*ERR.say: '=' x 40;
  }
  exit $exit ?? 0 !! 1;
}

# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

=begin pod
=head1 Advent of Code runner for Raku

Puzzle implementations implement a C<Day>:
  class DayX does Day {
    method part1(@lines) { ... }
    method part2(@lines) { ... }
  }

And a C<MAIN> function which passes the day and command line arguments to
C<runMain>:

  sub MAIN(Bool :v(:$verbose), *@input-files) {
    runMain(DayX, @input-files, :$verbose);
  }
=end pod

use v6.d;
use fatal;

unit module Runner:ver<0.0.0>:auth<Trevor Stone>;

role Day is export {
  method part1(@lines --> Str(Cool)) { ... }
  method part2(@lines --> Str(Cool)) { ... }
}

sub colored(Str $code, Str $text) { "\c[ESCAPE][{$code}m$text\c[ESCAPE][0m" }

class Outcome {
  has $.success;
  has $.message;

  multi method forResult("TODO", $want)  {
    my $status = colored("30;106", "TODO"); # black on bright cyan
    my $message = "\c[HEAVY EXCLAMATION MARK SYMBOL] $status implement it, want $want";
    Outcome.new(:success(True), :$message)
  }

  multi method forResult($got, "")  {
    my $status = colored("30;103", "UNKNOWN"); # black on bright yellow
    my $message = "\c[BLACK QUESTION MARK ORNAMENT] $status got $got";
    Outcome.new(:success(True), :$message)
  }

  multi method forResult($got, $want where { $got eq $want })  {
    my $status = colored("30;102", "SUCCESS"); # black on bright green
    my $message = "\c[WHITE HEAVY CHECK MARK] $status got $got";
    Outcome.new(:success(True), :$message)
  }

  multi method forResult($got, $want where { $got ne $want })  {
    my $status = colored("30;101", "FAILURE"); # black on bright red
    my $message = "\c[CROSS MARK] $status got $got, want $want";
    Outcome.new(:success(False), :$message)
  }
}

class RunContext {
  has Str @.lines;
  has Str $.input-file;
  has Str %.expected is rw;
  has Bool @.passed;
  has Bool $.verbose;

  method run-part(Day $day, Str $part) {
    my $expected = $.expected«$part» // '';
    my $name = $day.^name;
    my $function = $day.^lookup($part);
    if $!verbose {
      $*ERR.say: "Running $name $part on $!input-file ({@!lines.elems} lines)";
      $*ERR.flush;
    }
    my $start = now;
    my $result = $day.$function(@!lines);
    my $end = now;
    put "$part: $result";
    $*OUT.flush;
    my $outcome = Outcome.forResult($result, $expected);
    @!passed.push($outcome.success);
    if $!verbose {
      $*ERR.say: $outcome.message;
      $*ERR.say: "$part took {format-duration($end - $start)} on $!input-file";
      $*ERR.say: '=' x 40;
      $*ERR.flush;
    }
  }
}

sub format-duration(Duration:D $dur) {
  # Who knows why the Duration type doesn't have time unit methods
  given $dur {
    when $dur > 60 { "%d:%02d".sprintf($dur / 60, $dur % 60) }
    when $dur > 1 { "%.3fs".sprintf($dur) }
    when $dur > 0.001 { "%.3fms".sprintf($dur * 1000) }
    default { "%dμs".sprintf($dur * 1_000_000) }
  }
}

sub runMain(Day $day, @input-files, Bool :$verbose) is export {
  my $exit = all();
  for @input-files -> $input-file {
    my $handle = $input-file eq "-" ?? $*IN !! $input-file.IO;
    my Str @lines = $handle.lines;
    my $context = RunContext.new(:@lines, :$input-file, :$verbose);
    if ($input-file ne "-") {
      if (my $expected-file = $input-file.IO.extension('expected')).f {
        for $expected-file.lines {
          $context.expected«$0» = $1.trim.subst("\\n", "\n", :g) if m/(part \d+) \: \s* (.*)/;
        }
      }
    }
    $context.run-part($day, "part1");
    $context.run-part($day, "part2");
    $exit &= all($context.passed);
  }
  exit $exit ?? 0 !! 1;
}


# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

##
# Advent of Code runner for Perl.  Define part1 and part2 subroutines which take
# an array of strings (one per line in an input file), then require this file.
# Command line args are a list of input files and optionally -v or --verbose
# to enable information printed to stderr.

use charnames ':full';
use feature qw(say switch);
use open qw(:std :encoding(UTF-8));
use utf8;
use FindBin qw($Script);
use List::Util qw(any);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

my %outcome_symbols = (
  success => "\N{WHITE HEAVY CHECK MARK}",
  fail => "\N{CROSS MARK}",
  todo => "\N{HEAVY EXCLAMATION MARK SYMBOL}",
  unknown => "\N{BLACK QUESTION MARK ORNAMENT}",
);

(my $dayname = $Script) =~ s/\.pl$//;
my $verbose = any {/^-?-v(erbose)?$/} @ARGV;
my @inputs = grep(!/^-?-v(erbose)?$/, @ARGV);
@inputs = ('-') unless @inputs > 0;
my $success = 1;
foreach my $fname (@inputs) {
  my $fh;
  if ($fname eq '-') {
    $fh = STDIN;
  } else {
    open($fh, '<', $fname) or die "Could not read $fname: $!";
  }
  chomp(my @lines = readline $fh);
  close $fh;
  print STDERR "Running $dayname on $fname (" . +@lines . " lines)\n" if $verbose;
  foreach $part (qw(part1 part2)) {
    $success = &runpart($part, $fname, \@lines) || $exit;
  }
  # my $p1 = &part1(@lines);
  # say "part1: $p1";
  # say STDERR '=' x 40 if $verbose;
  # my $p2 = &part2(@lines);
  # say "part2: $p2";
  # say STDERR '=' x 40 if $verbose;
}
exit !$success;

sub runpart {
  my ($part, $fname, $lines) = @_;
  my %expected;
  if ($fname ne '-') {
    (my $ename = $fname) =~ s/\.txt$/.expected/;
    if (-e $ename and open(my $efh, '<', $ename)) {
      while (<$efh>) {
        chomp;
        if (/(part\d):\s*(.*)/) {
          $expected{$1} = $2;
        }
      }
    }
  }
  my $want = $expected{$part} // "";
  my $started = clock_gettime(CLOCK_MONOTONIC);
  my $got = &$part(@$lines);
  my $duration = clock_gettime(CLOCK_MONOTONIC) - $started;
  say "$part: $got";
  select()->flush();
  my $outcome; my $message = "got $got";
  if ($got eq $want) {
    $outcome = "success";
  } elsif ($got eq "TODO") {
    $outcome = "todo";
    $message = "implement it" . ($want ne "" ? ", want $want" : "");
  } elsif ($want eq "") {
    $outcome = "unknown";
  }
  else {
    $outcome = "fail"; $message .= ", want $want";
  }
  if ($verbose) {
    my $sym = $outcome_symbols{$outcome};
    say STDERR join(' ', $sym, uc($outcome), $message);
    my $dur = &format_duration($duration);
    say STDERR "$part took $dur on $fname";
    say STDERR '=' x 40;
    STDERR->flush();
  }
  return $outcome ne "fail";
}

sub format_duration {
  my $secs = shift;
  return sprintf '%dμs', $secs * 1_000_000 if $secs < 1 / 1000;
  return sprintf '%dms', $secs * 1_000 if $secs < 1;
  return sprintf '%.3fs', $secs if $secs < 60;
  return sprintf '%d:%02d', $secs / 60, $secs % 60 if $secs < 3600;
  return sprintf '%d:%02d:%02d', $secs / 3600, $secs % 3600 / 60, $secs % 60;
}

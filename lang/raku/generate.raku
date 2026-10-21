#!/usr/bin/env raku
# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generator script for a day's Advent of Code files.  Usage:
# generate.raku path/to/year/day1

use v6.d;
use fatal;

sub MAIN(Str:D $day-dir-name) {
  my $day-dir = $day-dir-name.IO;
  my $script = $day-dir.add($day-dir.basename ~ '.raku');
  if $script.e {
    $*ERR.say: "$script already exists, not creating any files";
    return;
  }
  my $year = $day-dir.parent(1).resolve.basename;
  my $class-name = $day-dir.basename.tc;
  my $day-num = $class-name.match(/\d+$/).Str;
  my $input-dir = "../input/$day-num".IO;
  my $lang-path = relative-link-path('lang/raku'.IO, $day-dir);
  $day-dir.mkdir;
  $day-dir.add($input-dir).mkdir;
  my %replace = :CLASS_NAME($class-name), :DAY_NUM($day-num), :YEAR($year),
    :COPY_DATE(now.DateTime.year), :LANG_PATH($lang-path);
  my $pat = /__(<{%replace.keys.join('|')}>)__/;
  my $template = $*PROGRAM-NAME.IO.sibling('template.raku').slurp;
  $script.spurt($template.subst($pat, { %replace<<$0>> }, :g));
  $script.chmod(0o755);
  for <input.actual.txt input.actual.expected> -> $fname {
    my $source = $input-dir.add($fname);
    my $target = $day-dir.add($fname);
    symlink($source, $target, :absolute(False)) unless $target.e;
  }
  for <example actual> X <txt expected> -> ($mid, $ext) {
    my $file = $day-dir.add("input.$mid.$ext");
    next if $file.e;
    given $ext {
      when 'txt' { $file.spurt('') }
      when 'expected' { $file.spurt("part1: \npart2: \n") }
    }
  }
}

# Path for a relative link to existing directory $source, to be placed in
# $target.  POSIX man pages use terminology 'ln source target' but Raku's Path
# docs use $target for the file that already exists.  This function uses the
# POSIX naming scheme, not Raku's.
sub relative-link-path($source, $target) {
  for 0..∞ -> $i {
    given my $parent = $target.absolute.IO.parent($i) {
      when $parent.add($source).e { return ('../' x $i).IO.add($source) }
      when $parent ~~ '/'.IO { return $source } # not great, maybe change
    }
  }
}

#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generator script for a day's Advent of Code files.  Usage:
# ./generate day1

sub MAIN(Str:D $day-dir-name) {
  my $day-dir = $day-dir-name.IO;
  my $class-name = $day-dir.basename.tc;
  my $day-num = $class-name.match(/\d+$/).Str;
  my $script = $day-dir.add($day-dir.basename ~ '.raku');
  $day-dir.mkdir;
  unless $script.f {
    my %replace = :CLASS_NAME($class-name), :DAY_NUM($day-num);
    my $pat = /__(<{%replace.keys.join('|')}>)__/;
    my $template = $*PROGRAM-NAME.IO.sibling('template.raku').slurp;
    $script.spurt($template.subst($pat, { %replace<<$0>> }, :g));
    $script.chmod(0o755);
  }
  for <input.example.txt input.actual.txt>.map({ $day-dir.add($_) }) -> $input {
    $input.spurt('') unless $input.f;
    .spurt("part1: \npart2: \n") unless .f given $input.extension('expected');
  }
}

#!/usr/bin/env raku
# Copyright __COPY_DATE__ Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

=begin pod
=head1 Advent of Code __YEAR__ day __DAY_NUM__
Read the puzzle at L<https://adventofcode.com/__YEAR__/day/__DAY_NUM__>
=end pod

use v6.d;
use fatal;
unless %*ENV<RAKULIB> {
  use lib $?FILE.IO.parent(1).add('__LANG_PATH__').resolve;
}
use Runner;


class Day__DAY_NUM__ does Day {
  method part1(Str @lines --> Str(Cool)) {
    "TODO";
  }

  method part2(Str @lines --> Str(Cool)) {
    "TODO";
  }
}

sub MAIN(Bool :v(:$verbose), *@input-files) {
  runMain(Day__DAY_NUM__, @input-files, :$verbose);
}

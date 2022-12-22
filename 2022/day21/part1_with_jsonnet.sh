#!/bin/bash
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/21

# Part 1 solution which transforms the input file with sed and evaluates it as
# a Jsonnet expression.  See https://jsonnet.org/

transform='
  s/:/::/
  s/$/,/
  s/ ([a-z])/ self.\1/g
  1i local expr = {
  $a };
  $a expr.root
'

for i in "$@" ; do
  echo "Running part1 on $i"
  sed -E -e "$transform" $i | jsonnet -
done

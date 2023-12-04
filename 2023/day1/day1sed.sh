#!/bin/sh
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

DIR=$(dirname -- "$0")
for file in "$@" ; do
  echo "Running day1 on $file ($(wc -l $file | sed 's/^ *//' | cut -f 1 -d' ') lines)" >&2
  echo "part1: " $(sed -f $DIR/day1part1.sed $file | xargs expr 0)
  echo "part2: " $(sed -f $DIR/day1part2.sed -f $DIR/day1part1.sed $file | xargs expr 0)
done

#!/bin/sh
# Copyright 2024 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Generate DOT and SVG graphviz output for AoC 2024 day 24 input.

DIR=`dirname -- "$0"`
for file in "$@" ; do
  sed -f "$DIR/day24graphviz.sed" $file >| ${file}.dot
  dot -Tsvg ${file}.dot >| ${file}.svg
  echo "Inspect ${file}.svg generated from ${file}.dot and run"
  echo "egrep 'z[0-9]{2}' $file | sort -k 5"
  echo "to spot any obvious differences."
done

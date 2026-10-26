#!/bin/zsh
# Copyright 2024 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Generate DOT and SVG graphviz output for AoC 2024 day 24 input.

DIR=${0:h}
OUT=$DIR/out
for file in "$@" ; do
  base=${file:t}
  sed -f "$DIR/graphvizday24.sed" $file >| $OUT/${base}.dot
  dot -Tsvg $OUT/${base}.dot >| $OUT/${base}.svg
  echo "Inspect $OUT/${base}.svg generated from $OUT/${base}.dot and run"
  echo "egrep 'z[0-9]{2}' $file | sort -k 5"
  echo "to spot any obvious differences."
done

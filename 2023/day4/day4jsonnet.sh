#!/bin/sh
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2023 day 4 solution in Jsonnet with sed to transform input.

DIR=$(dirname -- "$0")
TEMPDIR=$(mktemp -d)
cp "$DIR/day4.jsonnet" "$TEMPDIR"
for file in "$@" ; do
  echo "Running day4 on $file ($(wc -l $file | sed 's/^ *//' | cut -f 1 -d' ') lines)" >&2
  FILE="$TEMPDIR/$(basename "$file").jsonnet"
  sed -f "$DIR/day4jsonnet.sed" "$file" > "$FILE"
  jsonnet -S "$FILE" || cat $FILE
done

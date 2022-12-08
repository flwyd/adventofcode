#!/bin/bash
# Copyright 2022 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# https://adventofcode.com/2022/day/7

# Advent of Code 2022 day 7 solution using dd to make actual files and du to
# determine directory size.  Pass input file on stdin:
# actual_filesystem.sh < input.example.txt
# This doesn't get the right answer because du includes block sizes for
# directories.  One could use find and then group results hierarchically, but
# the whole idea of this script was to have du do the work :-)

BASEDIR="${BASEDIR-${TEMP-/tmp}/day7_actual_files_$$}"
if [[ -e "$BASEDIR" ]]; then
  echo "$BASEDIR already exists"
  exit 1
fi

echo "Operating in $BASEDIR"
mkdir "$BASEDIR"
cd "$BASEDIR"

while read -a command; do
  case "${command[0]}" in
    '$')
      case "${command[1]}${command[2]}" in
        ls) ;; # don't care
        cd/) cd "$BASEDIR" ;;
        cd..) cd .. ;;
        cd*) cd "${command[2]}" ;;
      esac
      ;;
    dir) mkdir "${command[1]}" ;;
    [0-9]*) dd if=/dev/zero of="$PWD/${command[1]}" bs=1 seek="${command[0]}" count=0 conv=excl 2>/dev/null ;;
  esac
done

# Unfortunately du includes directory block sizes even with -b (which implies
# --apparent size) so these numbers are wrong, and it picks the wrong directory
# on the example input.
echo -n "part1: "
du -b "$BASEDIR" | cut -f 1 | egrep '^[0-9]{1,5}$' | paste -sd+ - | bc
total=$(du -bs "$BASEDIR" | cut -f 1)
need=$((30000000 - (70000000 - $total)))
echo "total: $total need: $need"
du -b "$BASEDIR" | cut -f 1 | sort -n | while read dirsize; do
  if [[ "$dirsize" -ge "$need" ]]; then
    echo "part2: $dirsize"
    break
  fi
done
echo "cleaning $BASEDIR"
rm -r "$BASEDIR"

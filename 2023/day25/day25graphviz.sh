#!/bin/sh
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


DIR=$(dirname -- "$0")
TEMPDIR=$(mktemp -d)
GVPRPROG='BEG_G {
printf("part1: %d\npart2: Merry Christmas\n",
  nNodes(compOf($G, isNode($G, ARGV[0])))
  * nNodes(compOf($G, isNode($G, ARGV[1])))
)
}'
for file in "$@" ; do
  echo "Running day25 on $file ($(wc -l $file | sed 's/^ *//' | cut -f 1 -d' ') lines)" >&2
  dotfile="$TEMPDIR/$(basename $file).dot"
  svgfile="$TEMPDIR/$(basename $file).svg"
  sed -f "$DIR/day25graphviz.sed" $file > "$dotfile"
  neato -Tsvg "$dotfile" > "$svgfile"
  echo "Find the three obvious edges in file://$svgfile" >&2
  read -a edges -p "Edges to remove (e.g. abc dce fgh ijk lmn opq): "
  exclude=""
  for (( i=0 ; $i<6 ; i=$i+2 )) ; do
    exclude="$exclude|${edges[i]} -- ${edges[i+1]}|${edges[i+1]} -- ${edges[i]}"
  done
  egrep -v "${exclude:1}" "$dotfile" | gvpr -a "${edges[0]} ${edges[1]}" "$GVPRPROG"
done

# Copyright 2024 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# Transform AoC 204 day 24 input file into a DOT file for graphviz.
# Removes the initial x and y bit values.

1i\
digraph{

/^$/d
/: /d

s/\(...\) \([A-Z]*\) \(...\) -> \(...\)/subgraph { \1 \3 } -> \4 [ label = \2 ]/
s/.* -> \(z[0-9][0-9]\).*/\1 [ color = red ]\n&/

$a\
}

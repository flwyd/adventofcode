#!/usr/bin/env awk -f
# Copyright 2024 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generate markdown suitable for reddit.com/r/adventofcode solution megathreads
# by adding a header line, stripping boiler plate, and indenting four spaces.

/^end %Day[0-9]+/ { should_print = 0 }

should_print == 1 { printf "    %s\n", $0 }

/^Day[0-9]+/ {
  printf "[LANGUAGE: PostScript] "
  printf "([GitHub])(https://github.com/flwyd/adventofcode/blob/main/2024/%s)", FILENAME
  printf " with [my own standard library](https://github.com/flwyd/adventofcode/tree/main/2024/cob)\n"
  printf "\n[[WITTY COMMENTS HERE]]\n\n"
  should_print = 1
}

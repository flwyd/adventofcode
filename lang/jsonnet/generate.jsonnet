// Copyright 2025 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Generates a skeletal Jsonnet Advent of Code solution for a given day number.
// Note that jsonnet --multi allows writing several files, so this could also
// generate input.example.txt etc, but there's no way to check if it already
// exists to avoid overwriting non-skeleton changes.
// See https://github.com/google/jsonnet/issues/1259
function(day, year, copydate)
  |||
    // Copyright %(copydate)s Trevor Stone
    //
    // Use of this source code is governed by an MIT-style
    // license that can be found in the LICENSE file or at
    // https://opensource.org/licenses/MIT.

    // Advent of Code %(year)s day %(day)s
    // Read the puzzle at https://adventofcode.com/%(year)s/day/%(day)s

    function(lines) {
      dayname: 'day%(day)s',
      part1:
        'TODO',
      part2:
        'TODO',
    }
  ||| % { day: day, year: year, copydate: copydate }

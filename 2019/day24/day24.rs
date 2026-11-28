// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 24
//! Read the puzzle at <https://adventofcode.com/2019/day/24>
//!
//! Input is a 5x5 grid of `#` and `.` characters indicating presence or absence in a Conway's Game
//! of Life type simulation.  At each step, the neighbors of a position determine the next value of
//! that position.  If a position is occupied, it is vacated unless it has exactly one occupied
//! neighbor.  If a position is not occupied, it becomes occupied if it has exactly one or two
//! occupied neighbors.  In part 1, run the simulation until a state is repeated, then return the
//! 25-bit integer where each bit is 1 if the corresponding position is occupied, left-to-right,
//! top-to-bottom.  In part 2, the space is recursive, with the center position of the grid linking
//! to another grid.  The "inner ring" around the center all have 8 neighbors: 3 on the current
//! level and the 5 on the matching edge of the next level in; the positions around the edge of a
//! grid have four neighbors, 3 on the current level and one on the outer level at the corresponding
//! inner ring position.  The part 2 answer is the number of occupied squares across all levels
//! after 200 iterations.  (The example shows 99 after 10 iterations, but detecting example vs.
//! actual input is difficult, so input.example.txt has the 200-step answer.)

mod runner;

use runner::Day;
use std::collections::{HashSet, VecDeque};
use std::process::ExitCode;

pub struct Day24 {}

impl Day for Day24 {
  fn part1(lines: &[&str]) -> String {
    let visualize = std::env::var("VISUALIZE").is_ok();
    let mut grid = parse_input(lines);
    let mut seen = HashSet::new();
    seen.insert(grid);
    if visualize {
      eprint_grid(grid);
    }
    loop {
      let g = successor(grid);
      if visualize {
        eprint_grid(g);
      }
      if seen.contains(&g) {
        break g;
      }
      seen.insert(g);
      grid = g;
    }
    .to_string()
  }

  fn part2(lines: &[&str]) -> String {
    let visualize = std::env::var("VISUALIZE").is_ok();
    let initial = parse_input(lines);
    let mut levels = VecDeque::new();
    levels.push_back(initial);
    for _ in 0..200 {
      levels.push_front(0);
      levels.push_front(0);
      levels.push_back(0);
      levels.push_back(0);
      let mut next = VecDeque::new();
      for i in 1..levels.len() - 1 {
        next.push_back(level_successor(levels[i], levels[i - 1], levels[i + 1]));
      }
      levels = next;
    }
    if visualize {
      for &g in levels.iter().filter(|&g| *g > 0) {
        eprint_grid(g);
      }
    }
    levels.iter().map(|&g| g.count_ones()).sum::<u32>().to_string()
  }

  fn day_name() -> &'static str { "Day24" }
}

type Grid = u32;

fn mask(bit: u32, g: Grid) -> Grid { g & (1 << bit) }

fn level_successor(g: Grid, inner: Grid, outer: Grid) -> Grid {
  let inner_down =
    mask(0, inner) | mask(1, inner) | mask(2, inner) | mask(3, inner) | mask(4, inner);
  let inner_up =
    mask(20, inner) | mask(21, inner) | mask(22, inner) | mask(23, inner) | mask(24, inner);
  let inner_left =
    mask(4, inner) | mask(9, inner) | mask(14, inner) | mask(19, inner) | mask(24, inner);
  let inner_right =
    mask(0, inner) | mask(5, inner) | mask(10, inner) | mask(15, inner) | mask(20, inner);
  let outer_up = mask(7, outer);
  let outer_down = mask(17, outer);
  let outer_left = mask(11, outer);
  let outer_right = mask(13, outer);
  let mut s: Grid = 0;
  s |= level_bit_successor(0, g, outer_up, mask(5, g), outer_left, mask(1, g));
  s |= level_bit_successor(1, g, outer_up, mask(6, g), mask(0, g), mask(2, g));
  s |= level_bit_successor(2, g, outer_up, mask(7, g), mask(1, g), mask(3, g));
  s |= level_bit_successor(3, g, outer_up, mask(8, g), mask(2, g), mask(4, g));
  s |= level_bit_successor(4, g, outer_up, mask(9, g), mask(3, g), outer_right);
  s |= level_bit_successor(5, g, mask(0, g), mask(10, g), outer_left, mask(6, g));
  s |= level_bit_successor(6, g, mask(1, g), mask(11, g), mask(5, g), mask(7, g));
  s |= level_bit_successor(7, g, mask(2, g), inner_down, mask(6, g), mask(8, g));
  s |= level_bit_successor(8, g, mask(3, g), mask(13, g), mask(7, g), mask(9, g));
  s |= level_bit_successor(9, g, mask(4, g), mask(14, g), mask(8, g), outer_right);
  s |= level_bit_successor(10, g, mask(5, g), mask(15, g), outer_left, mask(11, g));
  s |= level_bit_successor(11, g, mask(6, g), mask(16, g), mask(10, g), inner_right);
  // mask 12, position [2,2], is a hole for the recursive level
  s |= level_bit_successor(13, g, mask(8, g), mask(18, g), inner_left, mask(14, g));
  s |= level_bit_successor(14, g, mask(9, g), mask(19, g), mask(13, g), outer_right);
  s |= level_bit_successor(15, g, mask(10, g), mask(20, g), outer_left, mask(16, g));
  s |= level_bit_successor(16, g, mask(11, g), mask(21, g), mask(15, g), mask(17, g));
  s |= level_bit_successor(17, g, inner_up, mask(22, g), mask(16, g), mask(18, g));
  s |= level_bit_successor(18, g, mask(13, g), mask(23, g), mask(17, g), mask(19, g));
  s |= level_bit_successor(19, g, mask(14, g), mask(24, g), mask(18, g), outer_right);
  s |= level_bit_successor(20, g, mask(15, g), outer_down, outer_left, mask(21, g));
  s |= level_bit_successor(21, g, mask(16, g), outer_down, mask(20, g), mask(22, g));
  s |= level_bit_successor(22, g, mask(17, g), outer_down, mask(21, g), mask(23, g));
  s |= level_bit_successor(23, g, mask(18, g), outer_down, mask(22, g), mask(24, g));
  s |= level_bit_successor(24, g, mask(19, g), outer_down, mask(23, g), outer_right);
  s
}

fn level_bit_successor(bit: u32, cur: Grid, up: Grid, down: Grid, left: Grid, right: Grid) -> Grid {
  let neighbors = up.count_ones() + down.count_ones() + left.count_ones() + right.count_ones();
  let curbit = cur & (1 << bit);
  (if curbit > 0 {
    if neighbors == 1 { 1 } else { 0 }
  } else {
    if neighbors == 1 || neighbors == 2 { 1 } else { 0 }
  }) << bit
}

fn successor(g: Grid) -> Grid {
  let mut s: Grid = 0;
  for i in 0..25 {
    let (x, y) = (i % 5, i / 5);
    let mut neighbors = 0;
    if y > 0 && g & (1 << (i - 5)) > 0 {
      neighbors += 1;
    }
    if y < 4 && g & (1 << (i + 5)) > 0 {
      neighbors += 1;
    }
    if x % 5 > 0 && g & (1 << (i - 1)) > 0 {
      neighbors += 1;
    }
    if x % 5 < 4 && g & (1 << (i + 1)) > 0 {
      neighbors += 1;
    }
    let curbit = g & (1 << i);
    let bit = if curbit > 0 && neighbors != 1 {
      0
    } else if curbit == 0 && neighbors == 1 || neighbors == 2 {
      1 << i
    } else {
      curbit
    };
    s |= bit;
  }
  s
}

fn eprint_grid(g: Grid) {
  for y in 0..5 {
    for x in 0..5 {
      let c = if g & (1 << (y * 5 + x)) > 0 { '#' } else { '.' };
      eprint!("{c}");
    }
    eprintln!("");
  }
  eprintln!("{g}");
}

fn parse_input(lines: &[&str]) -> Grid {
  assert_eq!(5, lines.len());
  assert_eq!(5, lines[0].len());
  let mut g: Grid = 0;
  for (y, line) in lines.iter().enumerate() {
    for (x, c) in line.chars().enumerate() {
      if c == '#' {
        g = g | 1 << (y * 5 + x);
      }
    }
  }
  g
}

pub fn main() -> ExitCode { runner::run_day::<Day24>() }

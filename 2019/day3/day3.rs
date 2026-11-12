// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 3
//! Read the puzzle at <https://adventofcode.com/2019/day/3>
//!
//! Input is two lists of cardinal direction moves in integer steps like `R1,U2,L3,D4`.  Two lines
//! start at coordinate `0,0` and follow each move, often crossing each other.  In part 1, find the
//! Manhattan distance of the closest intersection to (but excluding) `0,0`.  In part 2, find the
//! shortest combined path length leading to an intersection.

mod runner;

use runner::Day;
use std::collections::{HashMap, HashSet};
use std::iter;
use std::process::ExitCode;

pub struct Day3 {}

impl Day for Day3 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(2, lines.len());
    let a_path: HashSet<Vector> = walk(parse_line(lines[0])).into_keys().collect();
    let b_path: HashSet<Vector> = walk(parse_line(lines[1])).into_keys().collect();
    let mut best = i32::MAX;
    for v in a_path.intersection(&b_path) {
      best = best.min(v.magnitude());
    }
    if best == i32::MAX {
      panic!("Paths don't cross");
    }
    best.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(2, lines.len());
    let a_path = walk(parse_line(lines[0]));
    let b_path = walk(parse_line(lines[1]));
    let mut best = usize::MAX;
    for (v, adist) in a_path {
      if let Some(bdist) = b_path.get(&v) {
        best = best.min(adist + bdist);
      }
    }
    if best == usize::MAX {
      panic!("Paths don't cross");
    }
    best.to_string()
  }

  fn day_name() -> &'static str { "Day3" }
}

#[derive(Debug, Eq, Hash, PartialEq, Clone, Copy)]
struct Vector {
  x: i32,
  y: i32,
}

impl Vector {
  fn magnitude(&self) -> i32 { self.x.abs() + self.y.abs() }
  fn add(&self, other: &Vector) -> Vector { Vector { x: self.x + other.x, y: self.y + other.y } }
}

fn walk(steps: impl Iterator<Item = Vector>) -> HashMap<Vector, usize> {
  let mut path = HashMap::new();
  let mut cur = Vector { x: 0, y: 0 };
  for (i, delta) in steps.enumerate() {
    cur = cur.add(&delta);
    path.insert(cur, i + 1); // enumerate starts at 0, but first step is distance 1
  }
  path
}

fn parse_line(line: &str) -> impl Iterator<Item = Vector> {
  line.split(',').flat_map(|s| {
    let dir = &s[0..1];
    let dist = s[1..].parse::<usize>().unwrap();
    let unit = match dir {
      "L" => Vector { x: -1, y: 0 },
      "R" => Vector { x: 1, y: 0 },
      "U" => Vector { x: 0, y: 1 },
      "D" => Vector { x: 0, y: -1 },
      wrong => panic!("unexpected direction {wrong} in {s}"),
    };
    iter::repeat_n(unit, dist)
  })
}

pub fn main() -> ExitCode { runner::run_day::<Day3>() }

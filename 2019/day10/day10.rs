// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 10
//! Read the puzzle at <https://adventofcode.com/2019/day/10>
//!
//! Input is a grid of `#` asteroids and `.` empty space.  Asteroids don't take up a full grid
//! square, so line of sight from one asteroid to another is based on angles rather than quantized
//! integer-step movement.  In part 1, find the asteroid which has line of sight to the most other
//! asteroids and return that number.  In part 2, a laser on the part 1 asteroid points straight up
//! and rotates clockwise, destroying the first asteroid encountered along any ray; asteroids behind
//! that one will be zapped on subsequent cycles.  The answer to part 2 is the x coordinate times
//! 100 plus the y coordinate of the 200th zapped asteroid.

mod runner;

use runner::Day;
use std::collections::{HashMap, HashSet, VecDeque};
use std::f64::consts::TAU;
use std::process::ExitCode;

pub struct Day10 {}

impl Day for Day10 {
  fn part1(lines: &[&str]) -> String {
    let field = parse_grid(lines);
    let (_, best) = best_point(&field);
    best.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    let mut field = parse_grid(lines);
    let (best, _) = best_point(&field);
    field.sort_by_key(|p| best.distance(p));
    let mut angles: Vec<i32> = Vec::new();
    let mut by_angle: HashMap<i32, VecDeque<&Point>> = HashMap::new();
    for p in field.iter() {
      if *p == best {
        continue;
      }
      let angle = best.angle(&p);
      if let Some(q) = by_angle.get_mut(&angle) {
        q.push_back(p);
      } else {
        let mut q = VecDeque::new();
        q.push_back(p);
        by_angle.insert(angle, q);
        angles.push(angle);
      }
    }
    angles.sort();
    let mut zapped = 0;
    let mut last = 0;
    while zapped < field.len() - 1 {
      for a in angles.iter() {
        if let Some(p) = by_angle.get_mut(&a).unwrap().pop_front() {
          zapped += 1;
          last = p.x * 100 + p.y;
          if zapped == 200 {
            return last.to_string();
          }
        }
      }
    }
    last.to_string()
  }

  fn day_name() -> &'static str { "Day10" }
}

fn best_point(points: &Vec<Point>) -> (Point, usize) {
  let mut best = 0;
  let mut best_point = Point { x: -1, y: -1 };
  for source in points.iter() {
    let mut angles = HashSet::new();
    for target in points.iter() {
      if source == target {
        continue;
      }
      angles.insert(source.angle(target));
    }
    if angles.len() > best {
      best = angles.len();
      best_point = source.clone();
    }
  }
  (best_point, best)
}

fn parse_grid(lines: &[&str]) -> Vec<Point> {
  let mut result = Vec::new();
  for (y, row) in lines.iter().enumerate() {
    for (x, col) in row.chars().enumerate() {
      if col == '#' {
        result.push(Point { x: x as i32, y: y as i32 });
      }
    }
  }
  result
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Point {
  x: i32,
  y: i32,
}

impl Point {
  fn angle(&self, other: &Point) -> i32 {
    // Rust can't use floating point values as hash keys, and trig functions are not guaranteed to
    // be numerically stable.  Integer degrees are insufficiently granular for this problem's input,
    // so return millidegrees.  Grid has (0, 0) coordinate in top left, so increasing y is down.
    // Part 2 wants to move counterclockwise from straight up.  Use atan2(x,y) rather than y,x to go
    // clockwise (atan2(y,x) goes widdershins).  Swap the subtraction order so that 0 is up rather
    // than down.  And add [-π, -0) to τ so angles are all positive.
    let angle = ((other.x - self.x) as f64).atan2((self.y - other.y) as f64);
    (angle.rem_euclid(TAU).to_degrees() * 1000.0).round() as i32
  }

  fn distance(&self, other: &Point) -> i32 { (other.x - self.x).abs() + (other.y - self.y).abs() }
}

pub fn main() -> ExitCode { runner::run_day::<Day10>() }

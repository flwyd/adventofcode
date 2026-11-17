// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 12
//! Read the puzzle at <https://adventofcode.com/2019/day/12>
//!
//! Input is four lines of 3D coordinates, the initial coordinates of four bodies in mutual orbit.
//! Gravity pulls each pair of bodies towards each other in steps.  At each step, adjust each
//! body's velocity in each direction by -1, 0, or 1 for each other body in orbit.  Then adjust
//! the position of each body by its velocity.  The answer to part 1 is, after 1000 steps, the sum
//! of the energies of the bodies where energy is the magnitude of the position vector times the
//! magnitude of the velocity vector.  The answer to part 2 is the number of steps required until
//! the system repeats a state (all positions and velocities).  Part 2's answer is 49 bits, so
//! iterating through full system states is not practical.

mod runner;

use runner::Day;
use std::process::ExitCode;

pub struct Day12 {}

impl Day for Day12 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(4, lines.len());
    let mut bodies: Vec<_> = lines.into_iter().map(|line| parse_line(line)).collect();
    for _ in 0..1000 {
      let mut next = Vec::new();
      for a in bodies.iter() {
        let mut new = a.clone();
        for b in bodies.iter() {
          new.update_velocity(a, b);
        }
        new.apply_velocity();
        next.push(new);
      }
      bodies = next;
    }
    bodies.into_iter().map(|b| b.energy()).sum::<i32>().to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(4, lines.len());
    let bodies: Vec<_> = lines.into_iter().map(|line| parse_line(line)).collect();
    let xs = bodies.iter().map(|b| Axis { val: b.x, delta: 0 }).collect();
    let ys = bodies.iter().map(|b| Axis { val: b.y, delta: 0 }).collect();
    let zs = bodies.iter().map(|b| Axis { val: b.z, delta: 0 }).collect();
    let (x, y, z) = (find_loop(&xs), find_loop(&ys), find_loop(&zs));
    let a = x / gcd(x, z) * z;
    let b = a / gcd(a, y) * y;
    b.to_string()
  }

  fn day_name() -> &'static str { "Day12" }
}

fn parse_line(line: &str) -> Body {
  let nums = line.replace(|c: char| !(c == ' ' || c == '-' || c.is_ascii_digit()), "");
  let v: Vec<i32> = nums.split_whitespace().map(|s| s.parse().unwrap()).collect();
  Body { x: v[0], y: v[1], z: v[2], ..Default::default() }
}

fn gcd(a: usize, b: usize) -> usize {
  let (mut x, mut y) = (a.min(b), a.max(b));
  while x != 0 {
    y = y % x;
    (x, y) = (y, x);
  }
  y
}

fn find_loop(initial: &Vec<Axis>) -> usize {
  let mut bodies = initial.clone();
  for i in 1.. {
    let mut next = Vec::new();
    for a in bodies.iter() {
      let mut new = a.clone();
      for b in bodies.iter() {
        new.update_velocity(a, b);
      }
      new.apply_velocity();
      next.push(new);
    }
    if &next == initial {
      // Assume the initial state is part of a cyclic orbit, rather than some initial configuration
      // stabilizing into a cycle.  The latter can be detected by storing each state in a HashSet,
      // at the cost of a factor of 5 or 10 slower runtime.
      return i;
    }
    bodies = next;
  }
  0
}

#[derive(Clone, Copy, Default, Debug, Eq, Hash, PartialEq)]
struct Body {
  x:  i32,
  y:  i32,
  z:  i32,
  dx: i32,
  dy: i32,
  dz: i32,
}

impl Body {
  fn energy(&self) -> i32 {
    (self.x.abs() + self.y.abs() + self.z.abs()) * (self.dx.abs() + self.dy.abs() + self.dz.abs())
  }

  fn update_velocity(&mut self, a: &Self, b: &Self) {
    self.dx += (b.x - a.x).signum();
    self.dy += (b.y - a.y).signum();
    self.dz += (b.z - a.z).signum();
  }

  fn apply_velocity(&mut self) {
    self.x += self.dx;
    self.y += self.dy;
    self.z += self.dz;
  }
}

#[derive(Clone, Copy, Default, Debug, Eq, Hash, PartialEq)]
struct Axis {
  val:   i32,
  delta: i32,
}

impl Axis {
  fn update_velocity(&mut self, a: &Self, b: &Self) { self.delta += (b.val - a.val).signum(); }

  fn apply_velocity(&mut self) { self.val += self.delta; }
}

pub fn main() -> ExitCode { runner::run_day::<Day12>() }

// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 6
//! Read the puzzle at <https://adventofcode.com/2019/day/6>
//!
//! Input is lines like `ABC)6OT` meaning object `6OT` is in orbit around object `ABC`.  This forms
//! a tree of orbits with `COM` at the root.  The answer to part 1 is the total number of ancestor
//! relationships in the tree.  In part 2 the `YOU` and `SAN` objects represent you and Santa; the
//! answer is the number of steps from the object you are orbiting to the one Santa is orbiting.

mod runner;

use runner::Day;
use std::collections::{HashMap, VecDeque};
use std::process::ExitCode;

pub struct Day6 {}

impl Day for Day6 {
  fn part1(lines: &[&str]) -> String {
    let mut children: HashMap<String, Vec<String>> = HashMap::new();
    for line in lines {
      let (parent, child) = parse_line(line);
      if children.contains_key(&parent) {
        children.get_mut(&parent).unwrap().push(child);
      } else {
        children.insert(parent, vec![child]);
      }
    }
    let mut depth = HashMap::new();
    depth.insert("COM", 0);
    let mut q = VecDeque::from(["COM"]);
    while !q.is_empty() {
      let x = q.pop_front().unwrap();
      let d = depth.get(&x).unwrap() + 1;
      if let Some(kids) = children.get(x) {
        for y in kids {
          depth.insert(y, d);
          q.push_back(y);
        }
      }
    }
    depth.values().sum::<i32>().to_string()
  }

  fn part2(lines: &[&str]) -> String {
    let mut parents = HashMap::new();
    for line in lines {
      let (parent, child) = parse_line(line);
      parents.insert(child, parent);
    }
    let mut depth = HashMap::new();
    let mut count = 0;
    let mut cur = parents.get("YOU").expect("no YOU in input");
    loop {
      depth.insert(cur, count);
      count += 1;
      if let Some(p) = parents.get(cur) {
        cur = p;
      } else {
        break;
      }
    }
    count = 0;
    cur = parents.get("SAN").expect("no SAN in input");
    loop {
      if let Some(d) = depth.get(cur) {
        return (count + d).to_string();
      } else if let Some(p) = parents.get(cur) {
        cur = p;
        count += 1;
      } else {
        return String::from("no route from YOU to SAN");
      }
    }
  }

  fn day_name() -> &'static str { "Day6" }
}

fn parse_line(line: &str) -> (String, String) {
  let parts: Vec<&str> = line.split(')').collect();
  (String::from(parts[0]), String::from(parts[1]))
}

pub fn main() -> ExitCode { runner::run_day::<Day6>() }

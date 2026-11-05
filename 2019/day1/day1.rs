// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 1
//! Read the puzzle at <https://adventofcode.com/2019/day/1>
//!
//! Input is a list of integers representing weights.  Launch fuel is weight divided by 3 minus 2.
//! In part 1, the weight of fuel is ignored.  In part 2, add more fuel for the fuel weight.

mod runner;

use runner::Day;
use std::process::ExitCode;

pub struct Day1 {}

impl Day for Day1 {
  fn part1(lines: &[&str]) -> String {
    let weights = lines.into_iter().map(|line| parse_line(line));
    let sum: i64 = weights.map(|w| w / 3 - 2).sum();
    sum.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    let weights = lines.into_iter().map(|line| parse_line(line));
    let mut sum = 0;
    for weight in weights {
      let mut last = weight / 3 - 2;
      while last > 0 {
        sum += last;
        last = last / 3 - 2;
      }
    }
    sum.to_string()
  }

  fn day_name() -> &'static str { "Day1" }
}

fn parse_line(line: &str) -> i64 { line.parse::<i64>().unwrap() }

pub fn main() -> ExitCode { runner::run_day::<Day1>() }

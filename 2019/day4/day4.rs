// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 4
//! Read the puzzle at <https://adventofcode.com/2019/day/4>
//!
//! Input is a range of six digit numbers, output is the number of possible valid passwords in that
//! range.  In part 1, valid passwords have non-decreasing digits and at least one repeated digit.
//! In part 2, valid passwords need at least one digit repeated exactly twice.  111234 is valid in
//! part 1 but not part 2.

mod runner;

use runner::Day;
use std::process::ExitCode;

pub struct Day4 {}

impl Day for Day4 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let (first, last) = parse_line(lines[0]);
    // NOTE: functional style is about 50% slower than imperative in devel build
    (first..=last)
      .map(to_digits)
      .filter(|digits| {
        let mut double = false;
        for i in 1..digits.len() {
          if digits[i] < digits[i - 1] {
            return false;
          }
          double |= digits[i] == digits[i - 1];
        }
        double
      })
      .count()
      .to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let (first, last) = parse_line(lines[0]);
    let mut valid = 0;
    'outer: for num in first..=last {
      let digits = to_digits(num);
      let mut double = false;
      for i in 1..digits.len() {
        if digits[i] < digits[i - 1] {
          continue 'outer;
        }
        if digits[i] == digits[i - 1]
          && (i == 1 || digits[i] > digits[i - 2])
          && (i == digits.len() - 1 || digits[i + 1] > digits[i])
        {
          double = true;
        }
      }
      if double {
        valid += 1;
      }
    }
    valid.to_string()
  }

  fn day_name() -> &'static str { "Day4" }
}

fn to_digits(num: u32) -> [u32; 6] {
  let mut res = [0, 0, 0, 0, 0, 0];
  let mut cur = num;
  for i in 0..6 {
    res[5 - i] = cur % 10;
    cur /= 10;
  }
  res
}

fn parse_line(line: &str) -> (u32, u32) {
  let parts: Vec<&str> = line.split('-').collect();
  (parts[0].parse().unwrap(), parts[1].parse().unwrap())
}

pub fn main() -> ExitCode { runner::run_day::<Day4>() }

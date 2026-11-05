// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 2
//! Read the puzzle at <https://adventofcode.com/2019/day/2>
//!
//! Input is an Intcode program (comma-delimited integers).  Operands are 1 (add), 2 (multiply),
//! and 99 (halt).  Add and multiply take three arguments, all pointers, and perform the operation
//! on the first two operands, storing the value in the third address.  Output is the value in
//! address 0 after executing the halt instruction. In part 1, replace the second and third memory
//! addresses by `12,02`.  In part 2, find the values of the second and third addresses which would
//! put 1960720 in address 0, returning `100 * a + b`.

mod runner;

use runner::Day;
use std::process::ExitCode;

pub struct Day2 {}

impl Day for Day2 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let prog = parse_line(lines[0]);
    let (mut first, mut second) = (12, 2);
    if prog.len() <= 12 {
      // replacing with 12,02 only happens on actual input
      (first, second) = (prog[1], prog[2]);
    }
    if let Some(state) = run_with_replacements(lines[0], first, second) {
      state[0].to_string()
    } else {
      String::from("impossible")
    }
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let program = lines[0];
    let size = parse_line(program).len();
    for i in 0..size {
      for j in 0..size {
        if let Some(state) = run_with_replacements(program, i, j) {
          if state[0] == 19690720 {
            return (100 * i + j).to_string();
          }
        }
      }
    }
    String::from("impossible")
  }

  fn day_name() -> &'static str { "Day2" }
}

fn run_with_replacements(program: &str, first: usize, second: usize) -> Option<Vec<usize>> {
  let mut prog = parse_line(program);
  (prog[1], prog[2]) = (first, second);
  for i in (0..prog.len()).step_by(4) {
    if prog[i] == 99 {
      return Some(prog);
    }
    let a = prog[i + 1];
    let b = prog[i + 2];
    let c = prog[i + 3];
    if a >= prog.len() || b >= prog.len() || c >= prog.len() {
      return None;
    }
    prog[c] = match prog[i] {
      1 => prog[a] + prog[b],
      2 => prog[a] * prog[b],
      _ => return None,
    }
  }
  None
}

fn parse_line(line: &str) -> Vec<usize> {
  line.split(',').map(|s| s.parse::<usize>().unwrap()).collect()
}

pub fn main() -> ExitCode { runner::run_day::<Day2>() }

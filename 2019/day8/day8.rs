// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 8
//! Read the puzzle at <https://adventofcode.com/2019/day/8>
//!
//! Input is a long string of digits 0, 1, 2 (but in the first example is 0 through 9).  These
//! represent black (0), white (1), or transparent pixels stacked in several layers.  Layer size
//! is 25 by 6 for the actual input, 3 by 2 in the first example, and 4 by 4 in the second.
//! In part 1, the answer is the number of 1 pixels times the number of 2 pixels in the layer with
//! the fewest 0 pixels.  In part 2, stack layers (first layer on top) and print the pixelated
//! image; use your eyes or an OCR engine to read the letters.

mod runner;

use runner::Day;
use std::process::ExitCode;

pub struct Day8 {}

impl Day for Day8 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let digits = parse_line(lines[0]);
    let size = if digits.len() < 25 * 6 { 3 * 2 } else { 25 * 6 };
    let layer = digits.chunks(size).min_by_key(|c| c.iter().filter(|&&d| d == 0).count()).unwrap();
    (layer.iter().filter(|&&d| d == 1).count() * layer.iter().filter(|&&d| d == 2).count())
      .to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let digits = parse_line(lines[0]);
    let (cols, rows) = if digits.len() < 25 * 6 { (2, 2) } else { (25, 6) };
    let size = cols * rows;
    let mut image = ['_'].repeat(size);
    for i in 0..size {
      if let Some(color) = (i..digits.len()).step_by(size).map(|j| digits[j]).find(|&d| d < 2) {
        // this is Unicode LIGHT SHADE for 0 (ostensibly black) and DARK SHADE for 1 (white),
        // but I think it's easier to read this way on a light-theme terminal
        image[i] = if color == 0 { '\u{2591}' } else { '\u{2593}' };
      }
    }
    let mut s = String::with_capacity(size + rows);
    for (i, &c) in image.iter().enumerate() {
      if i % cols == 0 {
        s.push('\n');
      }
      s.push(c);
    }
    s
  }

  fn day_name() -> &'static str { "Day8" }
}

fn parse_line(line: &str) -> Vec<u32> { line.chars().map(|c| c.to_digit(10).unwrap()).collect() }

pub fn main() -> ExitCode { runner::run_day::<Day8>() }

// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 16
//! Read the puzzle at <https://adventofcode.com/2019/day/16>
//!
//! Input is a long string of digits which are treated as samples in a process similar to a
//! Fast Fourier Transform.  At each step, `output[i]` is the sum of each input value multiplied by
//! a phase value.  The phase values play the role of `e^i*2*pi/N*k` term in a real FFT algorithm,
//! cycling through 0, 1, 0, -1.  Each of those four values is repeated `i+1` times (0-based index)
//! with the first 0 removed.  Since the first `i` phase factors are 0, the additions form an
//! upper-triangular matrix, as shown in the puzzle.  The transform is run 100 times.  In part 1,
//! the answer is the first 8 digits of the resulting array.  In part 2, the input is repeated
//! 10,000 times and the first 7 digits of the initial input serve as an offset to the 8-digit
//! answer in the final array.
//!
//! Implementation note: part 2 takes a few seconds to run on example inputs and over 2 minutes on
//! the actual input.  A direct analog of the FFT divide-and-conquer approach like Cooley-Tukey is
//! challenging because the AoC phase factor isn't a proper root of unity, so determining twiddle
//! factors for sub-problems is non-obvious.

mod runner;

use runner::Day;
use std::iter::repeat_n;
use std::process::ExitCode;

pub struct Day16 {}

impl Day for Day16 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let mut input = parse_line(lines[0]);
    for _ in 0..100 {
      let mut output = vec![0; input.len()];
      for i in 0..input.len() {
        let pattern = repeat_n(0, i + 1)
          .chain(repeat_n(1, i + 1))
          .chain(repeat_n(0, i + 1))
          .chain(repeat_n(-1, i + 1))
          .cycle();
        output[i] = input.iter().zip(pattern.skip(1)).map(|(a, b)| a * b).sum::<i64>().abs() % 10;
      }
      input = output;
    }
    input[..8].iter().map(|x| x.to_string()).collect::<Vec<_>>().join("")
  }

  fn part2(lines: &[&str]) -> String {
    let cycles = 10_000;
    assert_eq!(1, lines.len());
    let parsed = parse_line(lines[0]);
    let mut input = Vec::from_fn(parsed.len() * cycles, |i| parsed[i % parsed.len()]);
    for _ in 0..100 {
      let mut sums = vec![0; input.len() + 1];
      for i in 0..input.len() {
        sums[i + 1] = input[i] + sums[i];
      }
      let mut output = vec![0; input.len()];
      for i in 0..output.len() {
        let span = i + 1;
        let mut val = 0;
        for k in 0..(output.len() / span) {
          let addstart = i + k * span * 4;
          if addstart >= sums.len() {
            break;
          }
          let substart = i + k * span * 4 + span * 2;
          let add = sums[(addstart + span).clamp(0, sums.len() - 1)] - sums[addstart];
          let sub = if substart < sums.len() {
            sums[(substart + span).clamp(0, sums.len() - 1)] - sums[substart]
          } else {
            0
          };
          val = val + add - sub;
        }
        output[i] = val.abs() % 10;
      }
      input = output;
    }
    let offset: usize = lines[0][..7].parse().unwrap();
    if offset + 7 < input.len() {
      input[offset..offset + 8].iter().map(|x| x.to_string()).collect::<Vec<_>>().join("")
    } else {
      // handle the small example
      input[..8].iter().map(|x| x.to_string()).collect::<Vec<_>>().join("")
    }
  }

  fn day_name() -> &'static str { "Day16" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.chars().map(|s| s.to_digit(10).unwrap() as i64).collect()
}

pub fn main() -> ExitCode { runner::run_day::<Day16>() }

// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

/// Advent of Code runner library for Rust.  Puzzle implementations implement
/// the Day trait by providing two functions which take a vector of String, one
/// per input line, and return an owned String with the answer.  The dayX.rs
/// file should have a main function which returns the ExitCode result of
/// runner::run_day::<DayX>().
use std::collections::HashMap;
use std::fs::File;
use std::io::{stdin, BufRead, BufReader};
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::{Duration, Instant};

pub trait Day {
  fn part1(input: &[String]) -> String;
  fn part2(input: &[String]) -> String;
  fn day_name() -> &'static str;
}

enum Outcome<'a> {
  Todo(&'a str),             // expected
  Unknown(&'a str),          // result
  Success(&'a str),          // result
  Failure(&'a str, &'a str), // result, expected
}

macro_rules! highlighted {
  ($color:expr, $word:expr) => {
    concat!("\x1B[", $color, "m", $word, "\x1B[0m")
  };
}

impl Outcome<'_> {
  fn from<'a>(result: &'a str, expected: &'a str) -> Outcome<'a> {
    if result == expected {
      Outcome::Success(result)
    } else if result == "TODO" {
      Outcome::Todo(expected)
    } else if expected.is_empty() {
      Outcome::Unknown(result)
    } else {
      Outcome::Failure(result, expected)
    }
  }

  fn exit_status(&self) -> bool {
    match self {
      Outcome::Todo(_) => true,
      Outcome::Unknown(_) => true,
      Outcome::Success(_) => true,
      Outcome::Failure(_, _) => false,
    }
  }

  fn message(&self) -> String {
    const HIGHLIGHT_SUCCESS: &str = highlighted!("30;102", "SUCCESS"); // black on bright green
    const HIGHLIGHT_FAILURE: &str = highlighted!("30;101", "FAILURE"); // black on bright red
    const HIGHLIGHT_UNKNOWN: &str = highlighted!("30;103", "UNKNOWN"); // black on bright yellow
    const HIGHLIGHT_TODO: &str = highlighted!("30;106", "TODO"); // black on bright cyan
    match self {
      Outcome::Unknown(result) => format!("❓ {} got {result}", HIGHLIGHT_UNKNOWN),
      Outcome::Success(result) => format!("✅ {} got {result}", HIGHLIGHT_SUCCESS),
      Outcome::Failure(result, expected) => {
        format!("❌ {} got {result}, want {expected}", HIGHLIGHT_FAILURE)
      }
      Outcome::Todo(expected) => {
        let exp = if expected.is_empty() { String::new() } else { format!(", want {expected}") };
        format!("❗ {} implement it{}", HIGHLIGHT_TODO, exp)
      }
    }
  }
}

pub fn run_day<D: Day>() -> ExitCode {
  let mut success = true;
  let args = std::env::args().skip(1);
  let (files, vflag): (Vec<String>, Vec<String>) = args.partition(|a| a != "-v");
  let verbose = vflag.len() > 0;
  let files = if files.is_empty() { vec![String::from("-")] } else { files };
  for fname in files {
    let r = run_file::<D>(&fname, verbose);
    match r {
      Ok(ok) => success &= ok,
      Err(error) => {
        eprintln!("Error running {} on {}: {}", D::day_name(), fname, error);
        success = false;
      }
    }
  }
  if success {
    ExitCode::SUCCESS
  } else {
    ExitCode::FAILURE
  }
}

pub fn run_file<D: Day>(fname: &String, verbose: bool) -> Result<bool, std::io::Error> {
  let (input, expected) = if fname == "-" {
    (stdin().lines().collect::<Result<Vec<String>, std::io::Error>>()?, HashMap::new())
  } else {
    (
      BufReader::new(File::open(fname)?)
        .lines()
        .collect::<Result<Vec<String>, std::io::Error>>()?,
      maybe_read_expected(fname),
    )
  };
  let result1 = run_part::<D>(PartNumber::One, fname, &input, &expected, verbose);
  let result2 = run_part::<D>(PartNumber::Two, fname, &input, &expected, verbose);
  Ok(result1 && result2)
}

enum PartNumber {
  One = 1,
  Two = 2,
}

fn run_part<D: Day>(
  part: PartNumber,
  fname: &String,
  input: &Vec<String>,
  expected: &HashMap<String, String>,
  verbose: bool,
) -> bool {
  let (name, func): (&str, fn(&[String]) -> String) = match part {
    PartNumber::One => ("part1", D::part1),
    PartNumber::Two => ("part2", D::part2),
  };
  if verbose {
    eprintln!("Running {} {name} on {fname} ({} lines)", D::day_name(), input.len());
  }
  let now = Instant::now();
  let result = func(input);
  let elapsed = now.elapsed();
  println!("{name}: {result}");
  let empty = &String::new();
  let outcome = Outcome::from(&result, expected.get(name).unwrap_or(empty));
  if verbose {
    eprintln!("{}", outcome.message());
    let dur = if elapsed > Duration::from_secs(60) {
      let mins = elapsed.as_secs() / 60;
      let secs = elapsed.as_secs() % 60;
      format!("{mins}:{secs:02}")
    } else if elapsed < Duration::from_micros(1) {
      format!("{elapsed:?}")
    } else {
      format!("{elapsed:.3?}")
    };
    eprintln!("{name} took {dur} on {fname}");
    eprintln!("{}", "=".repeat(40));
  }
  outcome.exit_status()
}

fn maybe_read_expected(fname: &String) -> HashMap<String, String> {
  let mut expected = HashMap::new();
  let mut path = PathBuf::from(fname);
  path.set_extension("expected");
  if path.exists() {
    if let Ok(f) = File::open(path) {
      for line in BufReader::new(f).lines().filter_map(|r| r.ok()) {
        if let Some((part, exp)) = line.split_once(':') {
          expected.insert(String::from(part), String::from(exp.trim()));
        }
      }
    }
  }
  expected
}

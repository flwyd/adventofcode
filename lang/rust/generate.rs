// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

use std::env;
use std::error::Error;
use std::ffi::OsStr;
use std::fs::{create_dir_all, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};

const TEMPLATE: &str = r##"// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

/// Advent of Code YEAR day DAYNUM
/// Read the puzzle at https://adventofcode.com/YEAR/day/DAYNUM
mod runner;

use runner::*;
use std::process::ExitCode;

pub struct DayDAYNUM {}

impl Day for DayDAYNUM {
  fn part1(#[allow(unused_variables)] input: &[String]) -> String {
    String::from("TODO")
  }

  fn part2(#[allow(unused_variables)] input: &[String]) -> String {
    String::from("TODO")
  }

  fn day_name() -> &'static str { "DayDAYNUM" }
}

pub fn main() -> ExitCode {
  runner::run_day::<DayDAYNUM>()
}
"##;

const MAKEFILE_TEMPLATE: &str = r##"# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

DAY = dayDAYNUM
RUSTC = rustc
RUSTBIN = bin/${DAY}rs

bin: rust

rust: ${RUSTBIN}

${RUSTBIN}: ${DAY}.rs runner.rs
	mkdir -p bin
	${RUSTC} -o ${RUSTBIN} ${DAY}.rs

runner.rs:
	ln -s ../../lang/rust/runner.rs .

clean: clean-rust

clean-rust:
	rm ${RUSTBIN}
"##;
const INPUT_EXPECTED: &str = "part1: \npart2: \n";

pub fn main() -> Result<(), String> {
  if env::args().len() == 1 {
    return Err(format!("Usage: {} path/to/dayX ...", env::args().nth(0).unwrap()));
  }
  // TODO other generators loop through path/to/dayX args, infer year from basedir
  for daydir in env::args().skip(1) {
    create_files(&daydir).map_err(|e| format!("could not generate files in {daydir}: {e}"))?;
  }
  Ok(())
}

fn create_files(daypath: &str) -> Result<(), Box<dyn Error>> {
  let dir = Path::new(daypath);
  let base = dir.file_name().and_then(OsStr::to_str).ok_or(format!("Empty path in {daypath}"))?;
  let day: String =
    base.chars().skip_while(|c| !c.is_ascii_digit()).take_while(char::is_ascii_digit).collect();
  if day.is_empty() {
    return Err(format!("no day number in {base}").into());
  }
  let year = dir
    .parent()
    .and_then(Path::file_name)
    .and_then(OsStr::to_str)
    .ok_or(format!("Parent of {daypath} is not a year"))?;
  // let base = format!("day{day}");
  // let mut dir = env::current_dir()?;
  // if !dir.as_path().ends_with(year) {
  //   dir.push(year);
  // }
  // dir.push(&base);
  create_dir_all(dir /*.as_path()*/)?;
  let rs = dir.join(&base).with_extension("rs");
  if rs.exists() {
    return Err(format!("{} already exists, not creating any files", rs.display()).into());
  }
  let text = TEMPLATE.replace("YEAR", &year).replace("DAYNUM", &day);
  maybe_create_file(rs.as_path(), &text)?;
  let makefile = dir.join("Makefile");
  let maketext = MAKEFILE_TEMPLATE.replace("DAYNUM", &day);
  maybe_create_file(makefile.as_path(), &maketext)?;
  let exp = dir.join("input.example.expected");
  maybe_create_file(exp.as_path(), INPUT_EXPECTED)?;
  let txt = dir.join("input.example.txt");
  maybe_create_file(txt.as_path(), "")?;
  let inputdir = dir.parent().ok_or("could not get parent")?.join("input");
  if inputdir.exists() {
    let inputday = inputdir.join(&day); // input/1/input.actual.txt not input/day1/input.actual.txt
    create_dir_all(inputday.as_path())?;
    let actualexp = inputday.join("input.actual.expected");
    maybe_create_file(actualexp.as_path(), INPUT_EXPECTED)?;
    let actualtxt = inputday.join("input.actual.txt");
    maybe_create_file(actualtxt.as_path(), "")?;
    for f in [actualexp, actualtxt] {
      let fname = f.file_name().unwrap().to_str().unwrap();
      let link = dir.join(fname);
      let source: PathBuf = ["..", "input", &day, &fname].iter().collect();
      maybe_link_file(source.as_path(), link.as_path())?;
    }
  } else {
    eprintln!("Missing {} dir, create a symlink", inputdir.display());
  }
  Ok(())
}

fn maybe_create_file(path: &Path, text: &str) -> std::io::Result<()> {
  if !path.exists() {
    // eprintln!("Creating {}", path.display());
    // TODO rust 1.77 let mut f = File::create_new(path)?;
    let mut f = File::create(path)?;
    f.write_all(text.as_bytes())?;
  }
  Ok(())
}

#[cfg(unix)]
fn maybe_link_file(source: &Path, link: &Path) -> io::Result<()> {
  if link.exists() {
    Ok(())
  } else {
    // eprintln!("Linking {} to {}", link.display(), source.display());
    std::os::unix::fs::symlink(source, link)
  }
}

#[cfg(windows)]
fn maybe_link_file(source: &Path, link: &Path) -> io::Result<()> {
  if link.exists() {
    Ok(())
  } else {
    // eprintln!("Linking {} to {}", link.display(), source.display());
    std::os::windows::fs::symlink_file(source, link)
  }
}

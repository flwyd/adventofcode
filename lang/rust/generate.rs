// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

/// Advent of Code template generator script for Rust.
/// Usage: generate 2001/day1 2001/day2 ...
/// Creates the named dayX directory and fills it with dayX.rs, a link to
/// runner.rs, and input.{example,actual}.{txt,expected} files.  Files which
/// already exist will not be changed.
use std::env;
use std::error::Error;
use std::ffi::OsStr;
use std::fs::{File, OpenOptions, create_dir_all};
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
RUSTC = rustc --edition=2024
RUSTBIN = bin/$(DAY)rs

bin: rust

rust: $(RUSTBIN)

$(RUSTBIN): $(DAY).rs runner.rs
	mkdir -p bin
	$(RUSTC) -o $(RUSTBIN) $(DAY).rs

runner.rs:
	ln -s RUNNERSOURCE .

clean: clean-rust

clean-rust:
	rm $(RUSTBIN)
"##;
const INPUT_EXPECTED: &str = "part1: \npart2: \n";

pub fn main() -> Result<(), String> {
  if env::args().len() == 1 {
    return Err(format!("Usage: {} path/to/dayX ...", env::args().nth(0).unwrap()));
  }
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
  create_dir_all(dir)?;
  let dirabs = dir.canonicalize().expect("dir should canonicalize");
  let year = dirabs
    .parent()
    .and_then(Path::file_name)
    .and_then(OsStr::to_str)
    .ok_or(format!("Parent of {daypath} is not a year"))?;
  let runnersource =
    relative_path_to_runner(dir).unwrap_or_else(|| PathBuf::from("../../lang/rust/runner.rs"));
  println!("Creating files in {}", dir.display());
  let rs = dir.join(&base).with_extension("rs");
  if rs.exists() {
    return Err(format!("{} already exists, not creating any files", rs.display()).into());
  }
  let runnersourcestr = runnersource.as_path().to_str().expect("non-unicode path");
  let text = TEMPLATE.replace("YEAR", &year).replace("DAYNUM", &day);
  maybe_create_file(rs.as_path(), &text)?;
  let makefile = dir.join("Makefile");
  let maketext =
    MAKEFILE_TEMPLATE.replace("DAYNUM", &day).replace("RUNNERSOURCE", &runnersourcestr);
  maybe_create_file(makefile.as_path(), &maketext)?;
  let runnerlink = dir.join("runner.rs");
  maybe_link_file(&runnersource, runnerlink.as_path())?;
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
  // Allow `cargo run day1` and let Rust ecosystem tools know about the files
  if let Some(cargo) = dir.parent().and_then(|p| Some(p.join("Cargo.toml")))
    && cargo.exists()
  {
    match OpenOptions::new().append(true).open(cargo.as_path()) {
      Ok(mut cargofile) => {
        if let Err(err) =
          write!(cargofile, "\n[[bin]]\nname = \"{base}\"\npath = \"{base}/{base}.rs\"\n")
        {
          eprintln!("Could not open {}: {}", cargo.display(), err);
        }
      }
      Err(err) => eprintln!("Could not open {}: {}", cargo.display(), err),
    }
  } else {
    eprintln!("No Cargo.toml in {year}");
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

fn relative_path_to_runner(start: &Path) -> Option<PathBuf> {
  let runner: &Path = Path::new("lang/rust/runner.rs");
  let canonical = start.canonicalize().ok()?;
  let mut path = PathBuf::new();
  for a in canonical.ancestors() {
    if a.join(runner).as_path().exists() {
      path.push(runner);
      return Some(path);
    }
    path.push("..");
  }
  None
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

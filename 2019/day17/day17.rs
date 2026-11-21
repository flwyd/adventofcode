// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 17
//! Read the puzzle at <https://adventofcode.com/2019/day/17>
//!
//! Input is an Intcode program whose outputs can now be interpreted as ASCII characters.
//! When the program is first run, it outputs a grid of `#` and `.` characters to indicate the
//! structure of a scaffold and an oriented robot represented by one of `^v<>`.  The part 1 answer
//! is the sum of the product of the 0-based (x,y) coordinates where horizontal and vertical
//! sections of the scaffold cross.  In part 2, change the first opcode to `2` and find a path
//! for the robot covering all scaffold squares.  Valid operations are right and left turns (`L`,
//! `R`) and moving forward a number of squares.  These move operations need to be split into a
//! very simple program with three move functions and a main function.  The main function can only
//! call move functions, the move functions cannot call main.  The functions are limited to 20
//! ASCII characters and each step is separated by a comma.  The Intcode program prompts for these
//! functions interactively, e.g. "Main:\n" and "Function A:\n".  It then asks "Continuous video
//! feed?", expecting a `y` or `n`.  It then follows the provided movement program, outputs the
//! ASCII drawing of the path and the robot's new position, and finally a number much larger than
//! ASCII range, which is the answer to part 2.

mod runner;

use runner::Day;
use std::collections::HashSet;
use std::fmt::{self, Display, Formatter};
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, SyncSender, channel, sync_channel};
use std::thread;

pub struct Day17 {}

impl Day for Day17 {
  fn part1(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("empty");
    }
    let text = explore_space(&parse_line(lines[0]));
    let lines: Vec<Vec<_>> = text.lines().map(|l| l.chars().collect()).collect();
    let mut answer = 0;
    for i in 1..lines.len() - 1 {
      let line = &lines[i];
      for j in 1..line.len() - 1 {
        let c = line[j];
        if c == '#'
          && line[j - 1] == '#'
          && line[j + 1] == '#'
          && lines[i - 1][j] == '#'
          && lines[i + 1][j] == '#'
        {
          answer += i * j;
        }
      }
    }
    answer.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("empty");
    }
    let program = parse_line(lines[0]);
    let text = explore_space(&program);
    let steps = find_path(&text);
    let ascii = AsciiProgram::from_steps(&steps);
    let mut p2program = program.clone();
    p2program[0] = 2;
    let (mut comp, input, output, done) = Computer::for_program(p2program);
    let in_handle = thread::spawn(move || {
      let visualize = std::env::var("VISUALIZE").is_ok();
      let text = format!("{}\n{}\n{}\n{}\nn\n", ascii.main, ascii.a, ascii.b, ascii.c);
      for c in text.chars() {
        if let Ok(()) = done.try_recv() {
          panic!("computer ended prematurely");
        }
        input.send(c as i64).unwrap();
        if visualize {
          eprint!("{c}");
        }
      }
    });
    let out_handle = thread::spawn(move || {
      let visualize = std::env::var("VISUALIZE").is_ok();
      while let Ok(i) = output.recv() {
        if i > 127 {
          return i;
        } else if visualize {
          eprint!("{}", char::from_u32(i as u32).unwrap());
        }
      }
      i64::MIN
    });
    comp.run();
    in_handle.join().unwrap();
    out_handle.join().unwrap().to_string()
  }

  fn day_name() -> &'static str { "Day17" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

fn explore_space(program: &Vec<i64>) -> String {
  let (mut comp, _input, output, done) = Computer::for_program(program.clone());
  let handle = thread::spawn(move || {
    let mut text = String::new();
    loop {
      if let Ok(()) = done.try_recv() {
        break text;
      }
      if let Ok(code) = output.recv() {
        let c = char::from_u32(code as u32).unwrap();
        text.push(c);
      }
    }
  });
  comp.run();
  handle.join().unwrap()
}

fn find_path(text: &str) -> Vec<Step> {
  let (robot_start, robot_char) = text
    .lines()
    .enumerate()
    .map(|(li, l)| {
      l.chars().enumerate().find_map(|(ci, c)| match c {
        '^' | '<' | '>' | 'v' => Some((Point { x: ci as i64, y: li as i64 }, c)),
        _ => None,
      })
    })
    .find_map(|x| x)
    .unwrap();
  let walls: HashSet<Point> = text
    .lines()
    .enumerate()
    .flat_map(|(li, l)| {
      l.chars().enumerate().filter_map(move |(ci, c)| match c {
        '#' => Some(Point { x: ci as i64, y: li as i64 }),
        _ => None,
      })
    })
    .collect();
  let mut visited = HashSet::new();
  let mut steps = Vec::new();
  let mut cur = robot_start;
  let mut heading = Heading::from(robot_char);
  while visited.len() < walls.len() {
    let right = heading.clockwise().next(cur);
    let left = heading.widdershins().next(cur);
    let turn = if walls.contains(&right) && !visited.contains(&right) {
      heading = heading.clockwise();
      Step::Right
    } else if walls.contains(&left) && !visited.contains(&left) {
      heading = heading.widdershins();
      Step::Left
    } else {
      panic!("{cur:?} is not at a corner")
    };
    steps.push(turn);
    let mut head_len = 0;
    while let next = heading.next(cur)
      && walls.contains(&next)
    {
      head_len += 1;
      visited.insert(next);
      cur = next;
    }
    steps.push(Step::Move(head_len))
  }
  steps
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct AsciiProgram {
  main: String,
  a:    String,
  b:    String,
  c:    String,
}

impl AsciiProgram {
  fn from_steps(steps: &Vec<Step>) -> AsciiProgram {
    // trailing comma to make textual replacement easy
    let joined = steps.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(",") + ",";
    for (i, _) in joined.match_indices(',') {
      let a_prog = &joined[0..=i];
      let split: Vec<_> = joined.split(&a_prog).collect();
      assert!(split[0].is_empty());
      for b_elem in split.iter() {
        for (j, _) in b_elem.match_indices(',') {
          let b_prog = &b_elem[0..=j];
          let c_elems = split.iter().flat_map(|s| s.split(b_elem)).filter(|s| !s.is_empty());
          for c_elem in c_elems {
            for (k, _) in c_elem.match_indices(',') {
              let c_prog = &c_elem[0..=k];
              if let Some(prog) = AsciiProgram::try_build(&joined, a_prog, b_prog, c_prog) {
                return prog;
              }
            }
          }
        }
      }
    }
    panic!("Could not match program constraints from {joined}");
  }

  // all params should have a trailing comma, which will be stripped in the program
  fn try_build(joined: &str, a: &str, b: &str, c: &str) -> Option<AsciiProgram> {
    let main = joined.replace(a, "A,").replace(b, "B,").replace(c, "C,");
    if main.chars().any(|c| !",ABC".contains(c)) {
      None
    } else if main.len() > 21 || a.len() > 21 || b.len() > 21 || c.len() > 21 {
      None
    } else {
      Some(AsciiProgram {
        main: String::from(main.trim_suffix(",")),
        a:    String::from(a.trim_suffix(",")),
        b:    String::from(b.trim_suffix(",")),
        c:    String::from(c.trim_suffix(",")),
      })
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Step {
  Move(usize),
  Right,
  Left,
}

impl Display for Step {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    match self {
      Self::Move(size) => write!(f, "{size}"),
      Self::Right => write!(f, "R"),
      Self::Left => write!(f, "L"),
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Point {
  x: i64,
  y: i64,
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Heading {
  Up = 0,
  Right = 1,
  Down = 2,
  Left = 3,
}

impl From<char> for Heading {
  fn from(c: char) -> Self {
    match c {
      '^' => Heading::Up,
      '>' => Heading::Right,
      'v' => Heading::Down,
      '<' => Heading::Left,
      wrong => panic!("invalid heading {wrong}"),
    }
  }
}

impl From<i8> for Heading {
  fn from(i: i8) -> Self {
    match i {
      x if x == Heading::Up as i8 => Heading::Up,
      x if x == Heading::Right as i8 => Heading::Right,
      x if x == Heading::Down as i8 => Heading::Down,
      x if x == Heading::Left as i8 => Heading::Left,
      wrong => panic!("invalid heading {wrong}"),
    }
  }
}

impl Heading {
  fn clockwise(&self) -> Self { Self::from((*self as i8 + 1).rem_euclid(4)) }
  fn widdershins(&self) -> Self { Self::from((*self as i8 - 1).rem_euclid(4)) }

  fn next(&self, cur: Point) -> Point {
    match self {
      Heading::Up => Point { x: cur.x, y: cur.y - 1 },
      Heading::Right => Point { x: cur.x + 1, y: cur.y },
      Heading::Down => Point { x: cur.x, y: cur.y + 1 },
      Heading::Left => Point { x: cur.x - 1, y: cur.y },
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum ParameterMode {
  Position = 0,
  Immediate = 1,
  Relative = 2,
}

impl TryFrom<i64> for ParameterMode {
  type Error = i64;

  fn try_from(digit: i64) -> Result<Self, Self::Error> {
    match digit {
      x if x == ParameterMode::Position as i64 => Ok(ParameterMode::Position),
      x if x == ParameterMode::Immediate as i64 => Ok(ParameterMode::Immediate),
      x if x == ParameterMode::Relative as i64 => Ok(ParameterMode::Relative),
      _ => Err(digit),
    }
  }
}

impl ParameterMode {
  fn address(&self, comp: &Computer, relative: usize) -> usize {
    match self {
      ParameterMode::Position => comp.mem[comp.pc + relative].try_into().unwrap(),
      ParameterMode::Immediate => comp.pc + relative,
      ParameterMode::Relative => (comp.base + comp.mem[comp.pc + relative]).try_into().unwrap(),
    }
  }
}

#[derive(Clone, Copy, Debug)]
enum Opcode {
  Add = 1,
  Multiply = 2,
  Input = 3,
  Output = 4,
  JumpIfTrue = 5,
  JumpIfFalse = 6,
  LessThan = 7,
  Equal = 8,
  AdjustBase = 9,
  Halt = 99,
}

impl TryFrom<i64> for Opcode {
  type Error = i64;

  fn try_from(i: i64) -> Result<Self, Self::Error> {
    match i {
      x if x == Opcode::Add as i64 => Ok(Opcode::Add),
      x if x == Opcode::Multiply as i64 => Ok(Opcode::Multiply),
      x if x == Opcode::Input as i64 => Ok(Opcode::Input),
      x if x == Opcode::Output as i64 => Ok(Opcode::Output),
      x if x == Opcode::JumpIfTrue as i64 => Ok(Opcode::JumpIfTrue),
      x if x == Opcode::JumpIfFalse as i64 => Ok(Opcode::JumpIfFalse),
      x if x == Opcode::LessThan as i64 => Ok(Opcode::LessThan),
      x if x == Opcode::Equal as i64 => Ok(Opcode::Equal),
      x if x == Opcode::AdjustBase as i64 => Ok(Opcode::AdjustBase),
      x if x == Opcode::Halt as i64 => Ok(Opcode::Halt),
      _ => Err(i),
    }
  }
}

#[derive(Clone, Copy, Debug)]
struct Instruction {
  opcode: Opcode,
  modes:  [ParameterMode; 3],
}

impl TryFrom<i64> for Instruction {
  type Error = i64;

  fn try_from(op: i64) -> Result<Self, Self::Error> {
    let opcode = (op % 100).try_into()?;
    let first = ((op / 100) % 10).try_into().expect("Unknown mode in {op}");
    let second = ((op / 1000) % 10).try_into().expect("Unknown mode in {op}");
    let third = ((op / 10_000) % 10).try_into().expect("Unknown mode in {op}");
    Ok(Instruction { opcode: opcode, modes: [first, second, third] })
  }
}

impl Instruction {
  fn apply(&self, comp: &mut Computer) -> usize {
    // return the number of steps to advance if the operation doesn't jump
    match self.opcode {
      Opcode::Add => {
        comp.set(3, &self.modes[2], comp.get(1, &self.modes[0]) + comp.get(2, &self.modes[1]));
        4
      }
      Opcode::Multiply => {
        comp.set(3, &self.modes[2], comp.get(1, &self.modes[0]) * comp.get(2, &self.modes[1]));
        4
      }
      Opcode::Input => {
        let val = comp.read_input();
        comp.set(1, &self.modes[0], val);
        2
      }
      Opcode::Output => {
        comp.write_output(comp.get(1, &self.modes[0]));
        2
      }
      Opcode::JumpIfTrue =>
        if let 0 = comp.get(1, &self.modes[0]) {
          3
        } else {
          comp.jump(2, &self.modes[1]);
          0
        },
      Opcode::JumpIfFalse =>
        if let 0 = comp.get(1, &self.modes[0]) {
          comp.jump(2, &self.modes[1]);
          0
        } else {
          3
        },
      Opcode::LessThan => {
        let (a, b) = (comp.get(1, &self.modes[0]), comp.get(2, &self.modes[1]));
        comp.set(3, &self.modes[2], if a < b { 1 } else { 0 });
        4
      }
      Opcode::Equal => {
        let (a, b) = (comp.get(1, &self.modes[0]), comp.get(2, &self.modes[1]));
        comp.set(3, &self.modes[2], if a == b { 1 } else { 0 });
        4
      }
      Opcode::AdjustBase => {
        comp.adjust_base(comp.get(1, &self.modes[0]));
        2
      }
      Opcode::Halt => {
        comp.halt();
        1
      }
    }
  }
}

#[derive(Debug, Default)]
struct Computer {
  mem:    Vec<i64>,                // opcodes and operands
  pc:     usize,                   // program counter, index into mem
  base:   i64,                     // base index into mem for relative mode
  input:  Option<Receiver<i64>>,   // read by opcode 3
  output: Option<SyncSender<i64>>, // written by opcode 4
  halted: Option<Sender<()>>,      // consumed by opcode 99
}

impl Computer {
  const EOF: i64 = i64::MIN;

  fn for_program(mem: Vec<i64>) -> (Computer, SyncSender<i64>, Receiver<i64>, Receiver<()>) {
    let (insend, input) = sync_channel(0);
    let (output, outreceive) = sync_channel(0);
    let (donesend, donerecv) = channel();
    (
      Computer {
        mem: mem,
        input: Some(input),
        output: Some(output),
        halted: Some(donesend),
        ..Default::default()
      },
      insend,
      outreceive,
      donerecv,
    )
  }

  fn run(&mut self) {
    while let Some(_) = self.halted {
      let pc = self.pc;
      if pc >= self.mem.len() {
        panic!("ran all instructions without halting");
      }
      let op: Instruction = self.mem[self.pc].try_into().expect("invalid instruction");
      let step = op.apply(self);
      if pc == self.pc {
        self.advance(step);
      }
    }
  }

  fn advance(&mut self, relative: usize) { self.pc += relative; }

  fn get(&self, relative: usize, mode: &ParameterMode) -> i64 {
    let addr = mode.address(&self, relative);
    if addr >= self.mem.len() { 0 } else { self.mem[addr] }
  }

  fn set(&mut self, relative: usize, mode: &ParameterMode, value: i64) {
    let addr = self.ensure_size(mode.address(&self, relative));
    self.mem[addr] = value;
  }

  fn jump(&mut self, relative: usize, mode: &ParameterMode) {
    let position: usize = mode.address(&self, relative).try_into().unwrap();
    self.pc = self.mem[position].try_into().unwrap();
  }

  fn read_input(&mut self) -> i64 {
    self.input.as_ref().expect("should not read input after halting").recv().unwrap_or(Self::EOF)
  }

  fn write_output(&mut self, val: i64) {
    self
      .output
      .as_ref()
      .expect("should not write output after halting")
      .send(val)
      .expect("error writing output");
  }

  fn adjust_base(&mut self, val: i64) { self.base = self.base.strict_add(val); }

  fn halt(&mut self) {
    if let Some(ref done) = self.halted {
      self.input = None;
      self.output = None;
      let _ = done.send(());
      self.halted = None;
    }
  }

  fn ensure_size(&mut self, position: usize) -> usize {
    if self.mem.len() <= position {
      self.mem.resize(position + 1, 0);
    }
    position
  }
}

pub fn main() -> ExitCode { runner::run_day::<Day17>() }

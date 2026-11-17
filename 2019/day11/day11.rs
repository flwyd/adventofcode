// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 11
//! Read the puzzle at <https://adventofcode.com/2019/day/11>
//!
//! Input is an Intcode program (input.example.txt is based on the puzzle's described behavior).
//! A robot starts facing up on a panel of pixels which all start black.  The program repeatedly
//! reads one input and produces two outputs.  The input is 1 if the current color is white, 0 if
//! it's currently black.  The first output is the color to paint the current pixel, the second
//! output is the direction to turn: 0 for left, 1 for right.  After turning, the robot moves
//! forward one pixel.  In part 1, the answer is the number of pixels that were painted any color
//! (each pixel is counted once).  In part 2, output the pixels and read the 8-character output with
//! OCR or human eyes.

mod runner;

use runner::Day;
use std::collections::HashSet;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::thread;

pub struct Day11 {}

impl Day for Day11 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let (visited, _) = run_program(lines[0], false);
    visited.len().to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let (_, changed) = run_program(lines[0], true);
    let minx = changed.iter().min_by_key(|p| p.x).unwrap().x;
    let maxx = changed.iter().max_by_key(|p| p.x).unwrap().x;
    let miny = changed.iter().min_by_key(|p| p.y).unwrap().y;
    let maxy = changed.iter().max_by_key(|p| p.y).unwrap().y;
    let mut lines = String::with_capacity(((maxx - minx + 2) * (maxy - miny + 1)) as usize);
    for y in miny..=maxy {
      lines.push('\n');
      for x in minx..=maxx {
        lines.push(if changed.contains(&Point { x, y }) { FOREGROUND } else { BACKGROUND });
      }
    }
    lines
  }

  fn day_name() -> &'static str { "Day11" }
}

const BACKGROUND: char = '░';
const FOREGROUND: char = '▓';

fn run_program(program: &str, initial_white: bool) -> (HashSet<Point>, HashSet<Point>) {
  let (mut comp, input, output) = Computer::for_program(parse_line(program));
  let visitor = thread::spawn(move || {
    let mut visited = HashSet::new();
    let mut changed = HashSet::new();
    let mut cur = Point { x: 0, y: 0 };
    let mut heading = Heading::Up;
    if initial_white {
      changed.insert(cur.clone());
    }
    loop {
      let cur_color = if changed.contains(&cur) { 1 } else { 0 };
      if let Err(_) = input.send(cur_color) {
        break (visited, changed);
      }
      let new_color = output.recv().expect("output should have color");
      if new_color == 1 {
        changed.insert(cur.clone());
      } else {
        changed.remove(&cur);
      }
      visited.insert(cur.clone());
      let turn = output.recv().expect("output should have turn");
      heading = heading.turn(turn == 1);
      cur = heading.advance(&cur);
    }
  });
  comp.run();
  visitor.join().unwrap()
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

impl From<i8> for Heading {
  fn from(i: i8) -> Self {
    match i {
      x if x == Heading::Up as i8 => Heading::Up,
      x if x == Heading::Right as i8 => Heading::Right,
      x if x == Heading::Down as i8 => Heading::Down,
      x if x == Heading::Left as i8 => Heading::Left,
      wrong => panic!("Unknown heading {wrong}"),
    }
  }
}

impl Heading {
  fn turn(&self, right: bool) -> Self {
    let delta = if right { 1 } else { -1 };
    Heading::from(((*self as i8) + delta).rem_euclid(4))
  }

  fn advance(&self, cur: &Point) -> Point {
    match self {
      Heading::Up => Point { x: cur.x, y: cur.y - 1 },
      Heading::Right => Point { x: cur.x + 1, y: cur.y },
      Heading::Down => Point { x: cur.x, y: cur.y + 1 },
      Heading::Left => Point { x: cur.x - 1, y: cur.y },
    }
  }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

#[derive(Clone, Copy, Debug)]
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
  mem:    Vec<i64>,              // opcodes and operands
  pc:     usize,                 // program counter, index into mem
  base:   i64,                   // base index into mem for relative mode
  input:  Option<Receiver<i64>>, // read by opcode 3
  output: Option<Sender<i64>>,   // written by opcode 4
  halted: bool,                  // set by opcode 99
}

impl Computer {
  fn for_program(mem: Vec<i64>) -> (Computer, Sender<i64>, Receiver<i64>) {
    let (insend, input) = channel();
    let (output, outreceive) = channel();
    (
      Computer { mem: mem, input: Some(input), output: Some(output), ..Default::default() },
      insend,
      outreceive,
    )
  }

  fn run(&mut self) {
    while !self.halted {
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
    self
      .input
      .as_ref()
      .expect("should not read input after halting")
      .recv()
      .expect("error reading input")
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
    self.halted = true;
    self.input = None;
    self.output = None;
  }

  fn ensure_size(&mut self, position: usize) -> usize {
    if self.mem.len() <= position {
      self.mem.resize(position + 1, 0);
    }
    position
  }
}

pub fn main() -> ExitCode { runner::run_day::<Day11>() }

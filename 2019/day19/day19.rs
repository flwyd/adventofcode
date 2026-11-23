// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 19
//! Read the puzzle at <https://adventofcode.com/2019/day/19>
//!
//! Input is an Intcode program which inputs two non-negative coordinates and outputs 1 if the
//! position is covered by a tractor beam and 0 if it is not.  The answer to part 1 is the number
//! of positions covered by the beam in a 50 by 50 square starting at 0,0.  The answer to part 2
//! is the top left position of a 100 by 100 box within the beam, with X multiplied by 10,000 and
//! added to Y.
//!
//! Implementation note: this Computer implementation reverts to synchronous, using `VeqDeque` in
//! place of channels for input and output.  This cuts the runtime to about one third (6 seconds to
//! 2 seconds) by not spawning 100,000+ short-lived threads.

mod runner;

use runner::Day;
use std::collections::{HashSet, VecDeque};
use std::process::ExitCode;

pub struct Day19 {}

impl Day for Day19 {
  fn part1(lines: &[&str]) -> String {
    let visualize = std::env::var("VISUALIZE").is_ok();
    if lines.is_empty() {
      return String::from("empty");
    }
    let program = parse_line(lines[0]);
    let mut answer = 0;
    for y in 0..=49 {
      for x in 0..=49 {
        let mut comp = Computer::for_program(program.clone(), VecDeque::new(), VecDeque::new());
        comp.input.push_back(x);
        comp.input.push_back(y);
        comp.run();
        let got = comp.output[0];
        answer += got;
        if visualize {
          if got == 0 {
            eprint!(".");
          } else {
            eprint!("#");
          }
        }
      }
      if visualize {
        eprintln!("");
      }
    }
    answer.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("empty");
    }
    let program = parse_line(lines[0]);
    let mut hundreds = HashSet::new();
    let mut left = 0; // edge of beam is a sloped line; disjoint pieces don't show up later
    for y in 0..11000 {
      let mut prev = 0;
      'outer: for x in (left - 1).max(0)..11000 {
        let mut comp = Computer::for_program(program.clone(), VecDeque::new(), VecDeque::new());
        comp.input.push_back(x);
        comp.input.push_back(y);
        comp.run();
        let got = comp.output[0];
        if got == 0 && prev == 1 {
          break;
        } else if got == 1 && prev == 0 {
          left = x;
        }
        prev = got;
        if x - left >= 99 {
          let start = x - 99;
          hundreds.insert((start, y));
          for i in (y - 99)..=y {
            if !hundreds.contains(&(start, i)) {
              continue 'outer;
            }
          }
          return (start * 10000 + y - 99).to_string();
        }
      }
    }
    String::from("did not find an answer")
  }

  fn day_name() -> &'static str { "Day19" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
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
  mem:    Vec<i64>,      // opcodes and operands
  pc:     usize,         // program counter, index into mem
  base:   i64,           // base index into mem for relative mode
  input:  VecDeque<i64>, // read by opcode 3
  output: VecDeque<i64>, // written by opcode 4
  halted: bool,          // set by opcode 99
}

impl Computer {
  fn for_program(mem: Vec<i64>, input: VecDeque<i64>, output: VecDeque<i64>) -> Computer {
    Computer { mem, input, output, ..Default::default() }
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

  fn read_input(&mut self) -> i64 { self.input.pop_front().expect("error reading input") }

  fn write_output(&mut self, val: i64) { self.output.push_back(val); }

  fn adjust_base(&mut self, val: i64) { self.base = self.base.strict_add(val); }

  fn halt(&mut self) { self.halted = true }

  fn ensure_size(&mut self, position: usize) -> usize {
    if self.mem.len() <= position {
      self.mem.resize(position + 1, 0);
    }
    position
  }
}

pub fn main() -> ExitCode { runner::run_day::<Day19>() }

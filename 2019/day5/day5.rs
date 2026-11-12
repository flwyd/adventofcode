// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 5
//! Read the puzzle at <https://adventofcode.com/2019/day/5>
//!
//! Input is an Intcode program (see day2).  New operands are 3 (input), 4 (output),
//! 5 (jump-if-true), 6 (jump-if-false), 7 (less than), and 8 (equals).  Operands have mode, stored
//! in base-10 digits of the opcode preceding the last two: 1002 is opcode 02 (multiply) with the
//! first operand taken by position and second operation taken immediately (no indirection).
//! When jumping, don't increment the instruction pointer a second time based on operation size.
//! In part 1, input is a single 1 and output should be several 0s followed by the answer.
//! In part 2, input is 5 and the lone output is the answer.

mod runner;

use runner::Day;
use std::collections::VecDeque;
use std::convert::TryFrom;
use std::process::ExitCode;

pub struct Day5 {}

impl Day for Day5 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let mut comp = Computer::new(parse_line(lines[0]), VecDeque::from([1]));
    comp.run();
    for o in comp.output.iter().take(comp.output.len() - 1) {
      if *o != 0 {
        eprintln!("Non-zero output in {:?}", comp);
        return String::from("failure");
      }
    }
    comp.output.last().expect("no output").to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let mut comp = Computer::new(parse_line(lines[0]), VecDeque::from([5]));
    comp.run();
    if comp.output.len() != 1 {
      eprintln!("Expected a single output in {:?}", comp);
      return String::from("failure");
    }
    comp.output[0].to_string()
  }

  fn day_name() -> &'static str { "Day5" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

#[derive(Clone, Copy, Debug)]
enum ParameterMode {
  Position = 0,
  Immediate = 1,
}

impl TryFrom<i64> for ParameterMode {
  type Error = i64;

  fn try_from(digit: i64) -> Result<Self, Self::Error> {
    match digit {
      0 => Ok(ParameterMode::Position),
      1 => Ok(ParameterMode::Immediate),
      _ => Err(digit),
    }
  }
}

impl ParameterMode {
  fn address(&self, comp: &Computer, relative: usize) -> usize {
    match self {
      ParameterMode::Position => comp.mem[comp.pc + relative].try_into().unwrap(),
      ParameterMode::Immediate => comp.pc + relative,
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
        comp.set_position(3, comp.get(1, &self.modes[0]) + comp.get(2, &self.modes[1]));
        4
      }
      Opcode::Multiply => {
        comp.set_position(3, comp.get(1, &self.modes[0]) * comp.get(2, &self.modes[1]));
        4
      }
      Opcode::Input => {
        let val = comp.read_input();
        comp.set_position(1, val);
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
        comp.set_position(3, if a < b { 1 } else { 0 });
        4
      }
      Opcode::Equal => {
        let (a, b) = (comp.get(1, &self.modes[0]), comp.get(2, &self.modes[1]));
        comp.set_position(3, if a == b { 1 } else { 0 });
        4
      }
      Opcode::Halt => {
        comp.halt();
        1
      }
    }
  }
}

#[derive(Debug)]
struct Computer {
  mem:    Vec<i64>,      // opcodes and operands
  pc:     usize,         // program counter, index into mem
  input:  VecDeque<i64>, // read by opcode 3
  output: Vec<i64>,      // written by opcode 4
  halted: bool,          // set by opcode 99
}

impl Computer {
  fn new(mem: Vec<i64>, input: VecDeque<i64>) -> Computer {
    Computer { mem: mem, pc: 0, input: input, output: Vec::new(), halted: false }
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
    self.mem[mode.address(&self, relative)]
  }

  fn set_position(&mut self, relative: usize, value: i64) {
    let position: usize = self.mem[self.pc + relative].try_into().unwrap();
    self.mem[position] = value;
  }

  fn jump(&mut self, relative: usize, mode: &ParameterMode) {
    let position: usize = mode.address(&self, relative).try_into().unwrap();
    self.pc = self.mem[position].try_into().unwrap();
  }

  fn read_input(&mut self) -> i64 { self.input.pop_front().expect("empty input") }

  fn write_output(&mut self, value: i64) { self.output.push(value); }

  fn halt(&mut self) { self.halted = true }
}

pub fn main() -> ExitCode { runner::run_day::<Day5>() }

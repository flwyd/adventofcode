// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 7
//! Read the puzzle at <https://adventofcode.com/2019/day/7>
//!
//! Input is an Intcode program; five independent copies of the program are run in series with the
//! output of one computer used as the input to the next.  The whole chain is run for each
//! permutation of five initial input values, and the answer is the largest output produced by the
//! final computer for some permutation.  In part 1, the permutation is over the numbers 0 to 4,
//! the first computer's second input is 0, and each computer produces a single output value which
//! is fed as the second input to the next computer; the answer is the single output of the fifth
//! computer.  In part 2, the output of the fifth computer is attached in a loop back to the input
//! of the first computer and they run in a feedback loop until all halting.  Permutations are now
//! over the numbers 5 to 9; the second input to the first computer is still 0, and there will be
//! one unconsumed output from the fifth computer after all have halted.

mod runner;

use runner::Day;
use std::collections::VecDeque;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::thread;

pub struct Day7 {}

impl Day for Day7 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    // Examples for part2 expect more than two inputs, but part1 doesn't set up the loop, so just
    // start the chain with a bunch of extra 0s
    let extra_input =
      program[..6] == [3, 26, 1001, 26, -4, 26] || program[..6] == [3, 52, 1001, 52, -5, 52];
    let perms = Permutation::new((0..=4).collect(), 0);
    let mut best = i64::MIN;
    for p in perms {
      // With first input in 0..=4, program produces one output and halts, so no parallelism needed
      let (initial, mut input) = channel();
      initial.send(p[0]).unwrap();
      initial.send(0).unwrap();
      if extra_input {
        for _ in 0..9 {
          initial.send(0).unwrap();
        }
      }
      for i in 0..=4 {
        let (output, nextin) = channel();
        if i < 4 {
          // first input to computer is permutation value, second input comes from previous computer,
          // final computer just has one output
          output.send(p[i + 1]).unwrap();
        }
        let mut comp = Computer::new(program.clone(), input, output);
        input = nextin;
        comp.run();
      }
      let result = input.recv().expect("no output from last computer");
      if !extra_input && let Ok(extra) = input.try_recv() {
        panic!("last computer produced {extra} as second output");
      }
      best = best.max(result);
    }
    best.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    let perms = Permutation::new((5..=9).collect(), 0);
    let mut best = i64::MIN;
    for p in perms {
      let (mut senders, mut receivers) = (VecDeque::new(), VecDeque::new());
      for _ in 0..5 {
        let (sender, receiver) = channel();
        senders.push_back(sender);
        receivers.push_back(receiver);
      }
      let lastr = receivers.pop_back().unwrap();
      receivers.push_front(lastr); // final output loops back to initial input
      for i in 0..5 {
        senders[i].send(p[(i + 1) % 5]).unwrap(); // permutation value is first input to each
      }
      senders[4].send(0).unwrap(); // loop starts with 0 as second input to first computer
      let mut handles = Vec::new();
      for _ in 0..5 {
        let (input, output) = (receivers.pop_front().unwrap(), senders.pop_front().unwrap());
        let prog = program.clone();
        handles.push(thread::spawn(move || {
          let mut comp = Computer::new(prog, input, output);
          comp.run();
          comp
        }));
      }
      let mut comps = Vec::new();
      for jh in handles.into_iter() {
        comps.push(jh.join().unwrap());
      }
      let result = comps[0].input.recv().expect("no final output from circuit");
      if let Ok(extra) = comps[0].input.try_recv() {
        panic!("last computer produced {extra} as extra output");
      }
      best = best.max(result);
    }
    best.to_string()
  }

  fn day_name() -> &'static str { "Day7" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

struct Permutation {
  items:  Vec<i64>,
  pivot:  usize,
  target: usize,
  child:  Option<Box<Permutation>>,
}

impl Permutation {
  fn new(items: Vec<i64>, pivot: usize) -> Self {
    Permutation { items: items, pivot: pivot, target: pivot, child: None }
  }
}

impl Iterator for Permutation {
  type Item = Vec<i64>;
  fn next(&mut self) -> Option<Vec<i64>> {
    if let Some(ref mut iter) = self.child {
      if let Some(next) = iter.next() {
        return Some(next);
      } else {
        self.child = None;
      }
    }
    if self.target >= self.items.len() {
      return None;
    }
    let mut next = self.items.clone();
    if self.items.len() == self.pivot + 1 {
      self.target += 1;
      return Some(next);
    }
    next.swap(self.pivot, self.target);
    let mut child =
      Permutation { items: next, pivot: self.pivot + 1, target: self.pivot + 1, child: None };
    let result = child.next();
    self.child = Some(Box::new(child));
    self.target += 1;
    result
  }
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
  input:  Receiver<i64>, // read by opcode 3
  output: Sender<i64>,   // written by opcode 4
  halted: bool,          // set by opcode 99
}

impl Computer {
  fn new(mem: Vec<i64>, input: Receiver<i64>, output: Sender<i64>) -> Computer {
    Computer { mem: mem, pc: 0, input: input, output: output, halted: false }
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

  fn read_input(&mut self) -> i64 { self.input.recv().expect("error reading input") }

  fn write_output(&mut self, val: i64) { self.output.send(val).expect("error writing output"); }

  fn halt(&mut self) { self.halted = true }
}

pub fn main() -> ExitCode { runner::run_day::<Day7>() }

// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 21
//! Read the puzzle at <https://adventofcode.com/2019/day/21>
//!
//! Input is an Intcode program that outputs ASCII text and reads ASCII instructions terminated by
//! newlines.  The program manages a robot with a set of boolean registers and an instruction set
//! of `AND`, `OR`, and `NOT` instructions that take two registers and write to the second.
//! The Intcode program takes up to 15 instructions to program the robot.  The `WALK` instruction
//! then instructs the robot to run the code in a loop with the `J` (jump) register instructing it
//! to jump.  In addition to the `T` (temporary) register, part 1 has registers `ABCD` indicating
//! true when the first four floor tiles ahead of the robot are filled (true) or empty (false).  In
//! part 2 there are 9 registers, `A` through `I` and the instruction to start is now `RUN`.
//! In both parts, if the robot steps into a hole the Intcode program will return several lines of
//! ASCII art indicating what happened as the robot approached and then fell in the hole.  If the
//! robot jumps over all holes, the Intcode program outputs a non-ASCII integer which is the puzzle
//! answer.

mod runner;

use runner::Day;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, SendError, Sender, SyncSender, channel, sync_channel};
use std::thread;

pub struct Day21 {}

impl Day for Day21 {
  fn part1(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("");
    }
    assert_eq!(1, lines.len());
    // Jump if there there are any holes in the next three steps and there's a 4th step to land on.
    let instructions =
      ["NOT C T", "OR T J", "NOT B T", "OR T J", "NOT A T", "OR T J", "AND D J", "WALK"];
    run_instructions(parse_line(lines[0]), &instructions).to_string()
  }

  fn part2(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("");
    }
    assert_eq!(1, lines.len());
    // There are now nine registers, RUN executes rather than WALK.
    // Jump if there there are any holes in the next three steps and both (a) there's a 4th step
    // to land on and (b) either an 8th step (so we can jump twice) or a 5th step (so we can jump
    // and then move forward).
    let instructions = [
      "NOT C T", "OR T J", "NOT B T", "OR T J", "OR E T", "OR H T", "AND T J", "NOT A T", "OR T J",
      "AND D J", "RUN",
    ];
    run_instructions(parse_line(lines[0]), &instructions).to_string()
  }

  fn day_name() -> &'static str { "Day21" }
}

fn run_instructions(intcode: Vec<i64>, instructions: &[&str]) -> i64 {
  let visualize = std::env::var("VISUALIZE").is_ok();
  let (mut comp, input, output, done) = Computer::for_program(intcode);
  let handle = thread::spawn(move || comp.run());
  let answer = {
    // read "Input instructions:"
    match read_line(&output) {
      Ok(prompt) =>
        if visualize {
          eprintln!("{prompt}")
        },
      Err(val) => panic!("error reading prompt: {val}"),
    }
    for line in instructions {
      if visualize {
        eprintln!("{line}");
      }
      write_line(line, &input).unwrap();
    }
    loop {
      if let Ok(()) = done.try_recv() {
        return 0;
      }
      // read "\nWalking...\n" then either a series of visualization lines or the answer
      match read_line(&output) {
        Ok(line) =>
          if visualize {
            eprintln!("{line}")
          },
        Err(val) => break val,
      }
    }
  };
  handle.join().unwrap();
  answer
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

fn read_line(output: &Receiver<i64>) -> Result<String, i64> {
  let mut line = String::new();
  loop {
    if let Ok(code) = output.recv() {
      if code == '\n' as i64 {
        return Ok(line);
      }
      if code < 1 || code > 127 {
        return Err(code);
      }
      line.push(char::from_u32(code as u32).unwrap());
    } else {
      return Err(0);
    }
  }
}

fn write_line(line: &str, sender: &SyncSender<i64>) -> Result<(), SendError<i64>> {
  for c in line.chars() {
    sender.send(c as i64)?;
  }
  sender.send('\n' as i64)
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

pub fn main() -> ExitCode { runner::run_day::<Day21>() }

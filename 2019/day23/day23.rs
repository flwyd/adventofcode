// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 23
//! Read the puzzle at <https://adventofcode.com/2019/day/23>
//!
//! Input is an Intcode program.  50 copies of the program are run on a network; the programs are
//! started by sending their node ID (0 to 49) as the first input.  Programs send a packet by
//! outputting three numbers: the node ID of the receiver and an X and Y value; the X and Y values
//! are then sent as input to the node with that ID.  I/O is non-blocking: if a program doesn't have
//! any pending packets, send a single -1 value, and programs may consume multiple packets before
//! sending any.  In part 1, the answer is the Y value of the first packet sent to node 255.
//! In part 2, packets sent to 255 are received by the NAT, which holds on to the latest packet.
//! If all computers become idle (no received outputs, no pending inputs), the NAT sends its latest
//! packet to node ID 0.  The part 2 answer is the first Y value which is sent twice in a row to
//! node 0.

mod runner;

use Opcode::*;
use ParameterMode::*;
use runner::Day;
use std::collections::VecDeque;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, SyncSender, channel, sync_channel};
use std::thread;

pub struct Day23 {}

impl Day for Day23 {
  fn part1(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::new();
    }
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    solve(&program, true).to_string()
  }

  fn part2(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::new();
    }
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    solve(&program, false).to_string()
  }

  fn day_name() -> &'static str { "Day23" }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

fn solve(program: &Vec<i64>, skip_nat: bool) -> i64 {
  let mut states = Vec::with_capacity(50);
  for _ in 0..50 {
    let (mut comp, input, output, _done) = Computer::for_program(program.clone());
    states.push(State { input, output, pending: VecDeque::new() });
    // this program doesn't have a halt instruction, so ignore done signal and don't retain a
    // JoinHandle.  TODO add a signal handler channel to Computer, send a control-C equivalent.
    thread::spawn(move || comp.run());
  }
  let main = thread::spawn(move || {
    for i in 0..50 {
      states[i].input.send(i as i64).unwrap();
    }
    let mut nat_packet = None;
    let mut last_nat_to_zero = None;
    loop {
      let mut did_something = false;
      for i in 0..50 {
        if let Ok(target) = states[i].output.try_recv() {
          let x = states[i].output.recv().unwrap();
          let y = states[i].output.recv().unwrap();
          if target == 255 {
            if skip_nat {
              return y;
            }
            nat_packet = Some((x, y));
          } else {
            states[target as usize].pending.push_back((x, y));
          }
          did_something = true;
        }
        if let Some((x, y)) = states[i].pending.pop_front() {
          thread::yield_now();
          if let Ok(()) = states[i].input.try_send(x) {
            states[i].input.send(y).unwrap();
          } else {
            states[i].pending.push_front((x, y));
          }
          did_something = true;
        } else {
          if let Ok(()) = states[i].input.try_send(-1) {}
        }
      }
      thread::yield_now();
      if !did_something && !skip_nat {
        if let Some((x, y)) = nat_packet {
          if last_nat_to_zero == nat_packet {
            return y;
          }
          states[0].pending.push_back((x, y));
          last_nat_to_zero = nat_packet;
        }
      }
    }
  });
  main.join().unwrap()
}

struct State {
  input:   SyncSender<i64>,
  output:  Receiver<i64>,
  pending: VecDeque<(i64, i64)>,
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
      x if x == Position as i64 => Ok(Position),
      x if x == Immediate as i64 => Ok(Immediate),
      x if x == Relative as i64 => Ok(Relative),
      _ => Err(digit),
    }
  }
}

impl ParameterMode {
  fn address(&self, comp: &Computer, relative: usize) -> usize {
    match self {
      Position => comp.mem[comp.pc + relative].try_into().unwrap(),
      Immediate => comp.pc + relative,
      Relative => (comp.base + comp.mem[comp.pc + relative]).try_into().unwrap(),
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
      x if x == Add as i64 => Ok(Add),
      x if x == Multiply as i64 => Ok(Multiply),
      x if x == Input as i64 => Ok(Input),
      x if x == Output as i64 => Ok(Output),
      x if x == JumpIfTrue as i64 => Ok(JumpIfTrue),
      x if x == JumpIfFalse as i64 => Ok(JumpIfFalse),
      x if x == LessThan as i64 => Ok(LessThan),
      x if x == Equal as i64 => Ok(Equal),
      x if x == AdjustBase as i64 => Ok(AdjustBase),
      x if x == Halt as i64 => Ok(Halt),
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
      Add => {
        comp.set(3, &self.modes[2], comp.get(1, &self.modes[0]) + comp.get(2, &self.modes[1]));
        4
      }
      Multiply => {
        comp.set(3, &self.modes[2], comp.get(1, &self.modes[0]) * comp.get(2, &self.modes[1]));
        4
      }
      Input => {
        let val = comp.read_input();
        comp.set(1, &self.modes[0], val);
        2
      }
      Output => {
        comp.write_output(comp.get(1, &self.modes[0]));
        2
      }
      JumpIfTrue =>
        if let 0 = comp.get(1, &self.modes[0]) {
          3
        } else {
          comp.jump(2, &self.modes[1]);
          0
        },
      JumpIfFalse =>
        if let 0 = comp.get(1, &self.modes[0]) {
          comp.jump(2, &self.modes[1]);
          0
        } else {
          3
        },
      LessThan => {
        let (a, b) = (comp.get(1, &self.modes[0]), comp.get(2, &self.modes[1]));
        comp.set(3, &self.modes[2], if a < b { 1 } else { 0 });
        4
      }
      Equal => {
        let (a, b) = (comp.get(1, &self.modes[0]), comp.get(2, &self.modes[1]));
        comp.set(3, &self.modes[2], if a == b { 1 } else { 0 });
        4
      }
      AdjustBase => {
        comp.adjust_base(comp.get(1, &self.modes[0]));
        2
      }
      Halt => {
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

pub fn main() -> ExitCode { runner::run_day::<Day23>() }

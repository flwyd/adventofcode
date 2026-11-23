// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 15
//! Read the puzzle at <https://adventofcode.com/2019/day/15>
//!
//! Input is an Intcode program which runs an endless loop tracking the position of an agent through
//! a space bounded by walls.  The program reads a cardinal direction as input and outputs a status
//! for what would happen if the agent moved in that direction: 0 if it would hit a wall (agent
//! doesn't move), 1 if it entered an empty space, or 2 if it found the target (1 and 2 move the
//! agent in the given direction).  The answer to part 1 is the shortest path from the initial
//! position to the target.  The answer to part 2 is the number of steps it would take to flood fill
//! from the target to fill the space.
//!
//! Implementation note: the program apparently halts if it gets an invalid direction as input, so
//! this Intcode computer returns `i64::MIN` as an EOF marker instead of a panic when a read opcode
//! tries to receive from a closed channel.

mod runner;

use runner::Day;
use std::collections::{HashMap, VecDeque};
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, SyncSender, channel, sync_channel};
use std::thread;

pub struct Day15 {}

impl Day for Day15 {
  fn part1(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("");
    }
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    let (mut comp, input, output, done) = Computer::for_program(program);
    let handle = thread::spawn(move || {
      let mut spaces = HashMap::new();
      let mut cur = Point { x: 0, y: 0 };
      spaces.insert(cur, Space::Empty);
      let mut path = VecDeque::new();
      loop {
        if let Ok(()) = done.try_recv() {
          panic!("program shouldn't end");
        }
        if path.is_empty() {
          path = path_to_unknown(cur, &spaces).expect("ran out of unexplored spaces");
        }
        let next = path.pop_front().unwrap();
        let dir = cur.direction_to(&next).expect("path should not include cur");
        input.send(dir as i64).expect("error sending input");
        let status = output.recv().expect("no status");
        match status {
          0 => {
            spaces.insert(next, Space::Wall);
          }
          1 => {
            spaces.insert(next, Space::Empty);
            cur = next;
          }
          2 => {
            if let Ok(_) = std::env::var("VISUALIZE") {
              eprint_space(&spaces, cur);
            }
            break path_distance(next, Point { x: 0, y: 0 }, &spaces);
          }
          wrong => panic!("unexpected status {wrong}"),
        }
      }
    });
    comp.run();
    handle.join().unwrap().to_string()
  }

  fn part2(lines: &[&str]) -> String {
    if lines.is_empty() {
      return String::from("");
    }
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    let (mut comp, input, output, done) = Computer::for_program(program);
    let handle = thread::spawn(move || {
      let mut spaces = HashMap::new();
      let mut cur = Point { x: 0, y: 0 };
      spaces.insert(cur, Space::Empty);
      let mut start = None;
      let mut path = VecDeque::new();
      // fully explore the space, taking note of the place flood fill will start
      loop {
        if let Ok(()) = done.try_recv() {
          panic!("program shouldn't end");
        }
        if path.is_empty() {
          if let Some(p) = path_to_unknown(cur, &spaces) {
            path = p;
          } else {
            break;
          }
        }
        let next = path.pop_front().unwrap();
        let dir = cur.direction_to(&next).expect("path should not include cur");
        input.send(dir as i64).expect("error sending input");
        let status = output.recv().expect("no status");
        match status {
          0 => {
            spaces.insert(next, Space::Wall);
          }
          1 => {
            spaces.insert(next, Space::Empty);
            cur = next;
          }
          2 => {
            spaces.insert(next, Space::Empty);
            cur = next;
            start = Some(next);
          }
          wrong => panic!("unexpected status {wrong}"),
        }
      }
      if let Ok(_) = std::env::var("VISUALIZE") {
        eprint_space(&spaces, start.unwrap());
      }
      // now calculate how long it takes to flood fill
      let mut steps = HashMap::new();
      steps.insert(start.unwrap(), 0);
      let mut ff = VecDeque::new();
      ff.push_back(start.unwrap());
      while let Some(p) = ff.pop_front() {
        let s = steps[&p];
        for dir in Direction::ALL {
          let n = p.neighbor(dir);
          if let Some(Space::Empty) = spaces.get(&n)
            && let None = steps.get(&n)
          {
            ff.push_back(n);
            steps.insert(n, s + 1);
          }
        }
      }
      *steps.values().max().unwrap()
    });
    comp.run();
    handle.join().unwrap().to_string()
  }

  fn day_name() -> &'static str { "Day15" }
}

fn path_to_unknown(cur: Point, spaces: &HashMap<Point, Space>) -> Option<VecDeque<Point>> {
  let mut q = VecDeque::new();
  q.push_back({
    let mut v = VecDeque::new();
    v.push_back(cur);
    v
  });
  while let Some(mut v) = q.pop_front() {
    let last = v[v.len() - 1];
    for d in Direction::ALL {
      let n = last.neighbor(d);
      match spaces.get(&n) {
        None => {
          v.push_back(n);
          v.pop_front(); // don't traverse initial point
          return Some(v);
        }
        Some(Space::Wall) => continue,
        Some(Space::Empty) => {
          if v.contains(&n) {
            continue;
          }
          let mut c = v.clone();
          c.push_back(n);
          q.push_back(c);
        }
      }
    }
  }
  None // no more unvisited spaces
}

fn path_distance(from: Point, to: Point, spaces: &HashMap<Point, Space>) -> usize {
  let mut seen = HashMap::new();
  seen.insert(from, 0);
  let mut q = VecDeque::new();
  q.push_back(from);
  while let Some(p) = q.pop_front() {
    let dist = seen[&p];
    for d in Direction::ALL {
      let n = p.neighbor(d);
      if n == to {
        return dist + 1;
      }
      if let Some(Space::Empty) = spaces.get(&n) {
        if !seen.contains_key(&n) {
          seen.insert(n, dist + 1);
          q.push_back(n);
        }
      }
    }
  }
  panic!("could not find a path from {from:?} to {to:?}");
}

fn eprint_space(spaces: &HashMap<Point, Space>, cur: Point) {
  let minx = spaces.keys().min_by_key(|p| p.x).unwrap().x;
  let miny = spaces.keys().min_by_key(|p| p.y).unwrap().y;
  let maxx = spaces.keys().max_by_key(|p| p.x).unwrap().x;
  let maxy = spaces.keys().max_by_key(|p| p.y).unwrap().y;
  for y in miny..=maxy {
    let mut buf = String::with_capacity((maxx - minx + 1) as usize);
    for x in minx..=maxx {
      let p = Point { x, y };
      if p == cur {
        buf.push('X');
      } else if p.x == 0 && p.y == 0 {
        buf.push('0');
      } else {
        buf.push(match spaces.get(&p) {
          None => ' ',
          Some(Space::Wall) => '#',
          Some(Space::Empty) => '.',
        });
      }
    }
    eprintln!("{buf}");
  }
}

fn parse_line(line: &str) -> Vec<i64> {
  line.split(',').map(|s| s.parse::<i64>().unwrap()).collect()
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Space {
  Empty,
  Wall,
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Direction {
  North = 1,
  South = 2,
  East = 3,
  West = 4,
}

impl Direction {
  const ALL: [Direction; 4] =
    [Direction::North, Direction::West, Direction::South, Direction::East];
}

impl From<i64> for Direction {
  fn from(val: i64) -> Direction {
    match val {
      x if x == Direction::North as i64 => Direction::North,
      x if x == Direction::South as i64 => Direction::South,
      x if x == Direction::East as i64 => Direction::East,
      x if x == Direction::West as i64 => Direction::West,
      wrong => panic!("unknown direction {wrong}"),
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Point {
  x: i64,
  y: i64,
}

impl Point {
  fn direction_to(&self, other: &Point) -> Option<Direction> {
    match ((self.x - other.x).signum(), (self.y - other.y).signum()) {
      (0, 0) => None,
      (_, -1) => Some(Direction::North),
      (-1, _) => Some(Direction::West),
      (_, 1) => Some(Direction::South),
      (1, _) => Some(Direction::East),
      _ => panic!("impossible signum"),
    }
  }

  fn neighbor(&self, dir: Direction) -> Point {
    match dir {
      Direction::North => Point { x: self.x, y: self.y - 1 },
      Direction::South => Point { x: self.x, y: self.y + 1 },
      Direction::East => Point { x: self.x + 1, y: self.y },
      Direction::West => Point { x: self.x - 1, y: self.y },
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

pub fn main() -> ExitCode { runner::run_day::<Day15>() }

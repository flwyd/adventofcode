// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 13
//! Read the puzzle at <https://adventofcode.com/2019/day/13>
//!
//! Input is an Intcode program with an implementation of
//! [Breakout](https://en.wikipedia.org/wiki/Breakout_(video_game)).  Program output comes in sets
//! of three numbers: an x and y position followed by a tile type.  When run unmodified (part 1),
//! the program prints an initial screen, the answer is the number of blocks shown.  In part 2,
//! change the first Intcode position to 2; the program is then interactive.  The interactive game
//! outputs `x=-1,y=0` and a score when the ball hits a block.  The program reads joystick input,
//! -1 to move left, 1 to move right, and 0 to stay put.  The program terminates if the paddle
//! misses the ball or when the final block is cleared.  Part 2's answer is the score after clearing
//! all blocks.
//!
//! When run with environment variable `VISUALIZE=ansi` or `VISUALIZE=ascii` the game board will be
//! shown in the terminal and updated each time the ball moves.  The `REFRESH_MICROS` environment
//! variable adjusts the refresh rate from the default 35000 (approximately 30 Hertz).  WARNING: if
//! you interrupt the program during the ANSI visualization your cursor may not be unhidden.

mod runner;

use runner::Day;
use std::collections::HashMap;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, Sender, SyncSender, channel, sync_channel};
use std::thread;
use std::time::Duration;

pub struct Day13 {}

impl Day for Day13 {
  fn part1(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let program = parse_line(lines[0]);
    let (mut comp, _, output, done) = Computer::for_program(program);
    let game = thread::spawn(move || {
      let visualizer = visualizer_from_env();
      let mut tiles = HashMap::new();
      loop {
        if let Ok(x) = output.recv() {
          let y = output.recv().expect("x should be followed by y");
          let id = output.recv().expect("y should be followed by tile id");
          let p = Point { x, y };
          match Tile::from(id) {
            Tile::Empty => {
              tiles.remove(&p);
            }
            tile => {
              tiles.insert(Point { x, y }, tile);
            }
          }
        }
        if let Ok(()) = done.try_recv() {
          let blocks = tiles.values().filter(|t| **t == Tile::Block).count();
          visualizer.visualize(&tiles, 0);
          break blocks;
        }
      }
    });
    comp.run();
    let blocks = game.join().unwrap();
    blocks.to_string()
  }

  fn part2(lines: &[&str]) -> String {
    assert_eq!(1, lines.len());
    let mut program = parse_line(lines[0]);
    program[0] = 2; // signal that we're playing
    let (mut comp, input, output, done) = Computer::for_program(program);
    let game = thread::spawn(move || {
      let visualizer = visualizer_from_env();
      let scorepos = Point { x: -1, y: 0 };
      let mut score = 0;
      let mut tiles = HashMap::new();
      let mut ball: Option<Point> = None;
      let mut paddle: Option<Point> = None;
      loop {
        if let (Some(a), Some(b)) = (paddle, ball) {
          let dir = (b.x - a.x).signum();
          if let Ok(()) = input.try_send(dir) {
            // eprintln!("moving {dir}");
          }
        }
        if let Ok(x) = output.try_recv() {
          let y = output.recv().expect("x should be followed by y");
          let id = output.recv().expect("y should be followed by tile id");
          let p = Point { x, y };
          if p == scorepos {
            score = id;
          } else {
            let tile = Tile::from(id);
            if tile == Tile::Empty {
              tiles.remove(&p);
            } else {
              tiles.insert(Point { x, y }, tile);
            }
            match tile {
              Tile::Ball => {
                ball = Some(p);
                visualizer.visualize(&tiles, score);
              }
              Tile::Paddle => paddle = Some(p),
              _ => (),
            }
          }
        }
        if let Ok(()) = done.try_recv() {
          visualizer.visualize(&tiles, score);
          break score;
        }
      }
    });
    comp.run();
    let score = game.join().unwrap();
    score.to_string()
  }

  fn day_name() -> &'static str { "Day13" }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Tile {
  Empty = 0,
  Wall = 1,
  Block = 2,
  Paddle = 3,
  Ball = 4,
}

impl From<i64> for Tile {
  fn from(val: i64) -> Tile {
    match val {
      x if x == Tile::Empty as i64 => Tile::Empty,
      x if x == Tile::Wall as i64 => Tile::Wall,
      x if x == Tile::Block as i64 => Tile::Block,
      x if x == Tile::Paddle as i64 => Tile::Paddle,
      x if x == Tile::Ball as i64 => Tile::Ball,
      wrong => panic!("unknown square type {wrong}"),
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Point {
  x: i64,
  y: i64,
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
  mem:    Vec<i64>,                // opcodes and operands
  pc:     usize,                   // program counter, index into mem
  base:   i64,                     // base index into mem for relative mode
  input:  Option<Receiver<i64>>,   // read by opcode 3
  output: Option<SyncSender<i64>>, // written by opcode 4
  halted: Option<Sender<()>>,      // consumed by opcode 99
}

impl Computer {
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
    if let Some(ref done) = self.halted {
      self.input = None;
      self.output = None;
      done.send(()).unwrap();
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

fn visualizer_from_env() -> Box<dyn Visualizer> {
  if let Ok(vis) = std::env::var("VISUALIZE") {
    let refresh = std::env::var("REFRESH_MICROS").unwrap_or(String::from("35000"));
    let delay = Duration::from_micros(refresh.parse().expect("REFRESH_MICROS should be a number"));
    if vis.eq_ignore_ascii_case("ansi") {
      Box::new(AnsiVisualizer { delay })
    } else {
      Box::new(AsciiVisualizer { delay })
    }
  } else {
    Box::new(NoopVisualizer())
  }
}

trait Visualizer {
  fn visualize(&self, tiles: &HashMap<Point, Tile>, score: i64);
}

struct NoopVisualizer();
impl Visualizer for NoopVisualizer {
  fn visualize(&self, _: &HashMap<Point, Tile>, _: i64) {}
}

struct AsciiVisualizer {
  delay: Duration,
}
impl Visualizer for AsciiVisualizer {
  fn visualize(&self, tiles: &HashMap<Point, Tile>, score: i64) {
    eprint!("{}", '\x0C'); // form feed/new page
    let maxx = tiles.keys().max_by_key(|p| p.x).unwrap().x;
    let maxy = tiles.keys().max_by_key(|p| p.y).unwrap().y;
    let mut blocks = 0;
    for y in 0..=maxy {
      let mut buf = String::with_capacity(maxx as usize + 1);
      for x in 0..=maxx {
        buf.push(match tiles.get(&Point { x, y }).unwrap_or(&Tile::Empty) {
          Tile::Empty => ' ',
          Tile::Wall => '.',
          Tile::Paddle => '-',
          Tile::Ball => '*',
          Tile::Block => {
            blocks += 1;
            '#'
          }
        });
      }
      eprintln!("{}", buf);
    }
    let st = format!("[ {score} ]");
    let bt = format!("[ {blocks} ]");
    eprintln!("{st}{}{bt}", "=".repeat((maxx as usize + 1).saturating_sub(st.len() + bt.len())));
    thread::sleep(self.delay);
  }
}

struct AnsiVisualizer {
  delay: Duration,
}
impl Visualizer for AnsiVisualizer {
  fn visualize(&self, tiles: &HashMap<Point, Tile>, score: i64) {
    eprint!("\x1B[?2026h"); // synchronized output, try to avoid flicker
    eprint!("\x1B[?25l"); // hide cursor
    eprint!("\x1B[H\x1B[J"); // move to top, clear display
    eprint!("\x1B[48;5;237m"); // gray background
    let maxx = tiles.keys().max_by_key(|p| p.x).unwrap().x;
    let maxy = tiles.keys().max_by_key(|p| p.y).unwrap().y;
    let mut blocks = 0;
    for y in 0..=maxy {
      for x in 0..=maxx {
        let (symbol, fg) = match tiles.get(&Point { x, y }).unwrap_or(&Tile::Empty) {
          Tile::Empty => (' ', 7),
          Tile::Wall => ('▒', 247),
          Tile::Ball => ('●', 1),
          Tile::Paddle => ('―', 7),
          Tile::Block => {
            blocks += 1;
            ('█', 16 + (y * 36 + (x - 2) % 36) % 216)
          }
        };
        eprint!("\x1B[{};{}H\x1B[38;5;{fg}m{symbol}", y + 1, x + 1);
      }
    }
    let st = format!("[ {score} ]");
    let bt = format!("[ {blocks} ]");
    eprint!("\x1B[{};1H", maxy + 2); // move to bottom, print status line
    eprint!("{st}{}{bt}", " ".repeat((maxx as usize + 1).saturating_sub(st.len() + bt.len())));
    if blocks == 0 {
      eprint!("\x1B[{};1H", maxy + 3); // put cursor back
      eprint!("\x1B[?25h"); // show cursor
    }
    eprint!("\x1B[?2026l"); // end synchronized output
    eprint!("\x1B[0m"); // reset colors
    thread::sleep(self.delay);
  }
}

pub fn main() -> ExitCode { runner::run_day::<Day13>() }

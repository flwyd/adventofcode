// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 18
//! Read the puzzle at <https://adventofcode.com/2019/day/18>
//!
//! Input is a grid with lowercase letters indicating keys and uppercase letters indicating doors.
//! An agent starts at the `@` position and can move through doors if it's visited the
//! corresponding key.  In part 1 the answer is the minimum number of steps to visit every key.
//! In part 2, the 8 open spaces around the starting position are replaced with a wall in a `+`
//! configuration with one agent starting at each corner.  The grid is now in four disjoint
//! sections.  At each step you can move one agent; agents can pass through a door if any agent has
//! visited the matching key.  The part 2 answer is still the number of steps to visit each key.

mod runner;

use runner::Day;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::process::ExitCode;

pub struct Day18 {}

impl Day for Day18 {
  fn part1(lines: &[&str]) -> String {
    let (spaces, start, want_keys) = parse_input(lines);
    let mut seen = HashMap::new();
    let mut pq = BinaryHeap::new();
    pq.push(State { cost: 0, cur: start, keys: 0 });
    while let Some(state) = pq.pop() {
      if state.keys == want_keys {
        return state.cost.to_string();
      }
      let seenkey = (state.cur, state.keys);
      if let Some(&cost) = seen.get(&seenkey)
        && cost <= state.cost
      {
        continue;
      }
      seen.insert(seenkey, state.cost);
      for s in state.successors(&spaces) {
        pq.push(s);
      }
    }
    format!("{}", "oh crap")
  }

  fn part2(lines: &[&str]) -> String {
    let (mut spaces, start, want_keys) = parse_input(lines);
    for p in [
      &Point { x: start.x, y: start.y - 1 },
      &Point { x: start.x, y: start.y + 1 },
      &Point { x: start.x - 1, y: start.y },
      &Point { x: start.x + 1, y: start.y },
      &Point { x: start.x - 1, y: start.y - 1 },
      &Point { x: start.x - 1, y: start.y + 1 },
      &Point { x: start.x + 1, y: start.y - 1 },
      &Point { x: start.x + 1, y: start.y + 1 },
    ] {
      if spaces.get(&p) != Some(&Tile::Space) {
        return format!("example does not work");
      }
      spaces.remove(p);
    }
    spaces.remove(&start);
    let starts = [
      Point { x: start.x - 1, y: start.y - 1 },
      Point { x: start.x - 1, y: start.y + 1 },
      Point { x: start.x + 1, y: start.y - 1 },
      Point { x: start.x + 1, y: start.y + 1 },
    ];
    for p in starts.iter() {
      spaces.insert(*p, Tile::Start);
    }
    let mut seen = [HashMap::new(), HashMap::new(), HashMap::new(), HashMap::new()];
    for i in 0..4 {
      seen[i].insert((starts[i], 0), 0);
    }
    let mut pq = BinaryHeap::new();
    pq.push(State4 { cost: 0, cur: starts, keys: 0 });
    let mut seen4 = HashMap::new();
    while let Some(state) = pq.pop() {
      if state.keys == want_keys {
        if let Ok(_) = std::env::var("VISUALIZE") {
          eprint_grid(&spaces, &state);
        }
        return state.cost.to_string();
      }
      let seenkey = (state.cur, state.keys);
      if let Some(&cost) = seen4.get(&seenkey)
        && cost <= state.cost
      {
        continue;
      }
      seen4.insert(seenkey, state.cost);
      for s4 in state.successors(&spaces) {
        pq.push(s4);
      }
    }
    format!("{}", "uh oh")
  }

  fn day_name() -> &'static str { "Day18" }
}

fn eprint_grid(spaces: &HashMap<Point, Tile>, state: &State4) {
  let minx = spaces.keys().min_by_key(|p| p.x).unwrap().x;
  let miny = spaces.keys().min_by_key(|p| p.y).unwrap().y;
  let maxx = spaces.keys().max_by_key(|p| p.x).unwrap().x;
  let maxy = spaces.keys().max_by_key(|p| p.y).unwrap().y;
  let wall_line = String::from("#".repeat((3 + maxx - minx) as usize));
  eprintln!("{wall_line}");
  for y in miny..=maxy {
    let mut line = String::new();
    line.push('#');
    for x in minx..=maxx {
      let p = Point { x, y };
      if state.cur.contains(&p) {
        line.push('@');
      } else {
        line.push(match spaces.get(&p) {
          None => '#',
          Some(Tile::Space) | Some(Tile::Start) => '.',
          Some(Tile::Door(d)) => bitmask_char(*d, true),
          Some(Tile::Key(k)) => bitmask_char(*k, false),
        });
      }
    }
    line.push('#');
    eprintln!("{line}");
  }
  eprintln!("{wall_line}");
  let mut keys = String::new();
  for c in 'a'..'z' {
    keys.push(if state.keys & char_bitmask(c, false) != 0 { c } else { c.to_ascii_uppercase() });
  }
  eprintln!("{}: {keys}", state.cost);
}

fn parse_input(lines: &[&str]) -> (HashMap<Point, Tile>, Point, u32) {
  let mut spaces = HashMap::new();
  let mut start = Point { x: 0, y: 0 };
  let mut keys = 0u32;
  for (y, line) in lines.iter().enumerate() {
    for (x, c) in line.chars().enumerate() {
      if c == '#' {
        continue;
      }
      let p = Point { x: x as i32, y: y as i32 };
      let tile = match c {
        '#' => continue,
        '.' => Tile::Space,
        '@' => Tile::Start,
        x if x.is_ascii_alphabetic() && x.is_uppercase() => Tile::Door(char_bitmask(x, true)),
        x if x.is_ascii_alphabetic() && x.is_lowercase() => Tile::Key(char_bitmask(x, false)),
        wrong => panic!("unexpected character {wrong}"),
      };
      spaces.insert(p, tile);
      if let Tile::Start = tile {
        start = p;
      }
      if let Tile::Key(k) = tile {
        keys |= k;
      }
    }
  }
  (spaces, start, keys)
}

fn char_bitmask(c: char, upper: bool) -> u32 {
  1 << (c as u32 - if upper { 'A' } else { 'a' } as u32)
}

fn bitmask_char(u: u32, upper: bool) -> char {
  match u.lowest_one() {
    None => ' ',
    Some(pos) => char::from_u32(pos + if upper { 'A' } else { 'a' } as u32).unwrap(),
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
enum Tile {
  Space,
  Start,
  Door(u32),
  Key(u32),
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct State4 {
  cost: u32,
  cur:  [Point; 4],
  keys: u32,
}

impl State4 {
  fn successors(&self, spaces: &HashMap<Point, Tile>) -> Vec<State4> {
    let mut res = Vec::new();
    for i in 0..4 {
      let s = State { cost: self.cost, cur: self.cur[i], keys: self.keys };
      let mut visited = HashMap::new();
      let mut found = HashMap::new();
      s.reachable_keys(&spaces, &mut visited, &mut found);
      for n in found.values() {
        let mut cur = self.cur.clone();
        cur[i] = n.cur;
        let s4 = State4 { cost: n.cost, cur: cur, keys: n.keys };
        res.push(s4);
      }
    }
    res
  }
}

impl Ord for State4 {
  fn cmp(&self, other: &Self) -> Ordering {
    (other.cost + other.keys.count_zeros()).cmp(&(self.cost + self.keys.count_zeros()))
  }
}

impl PartialOrd for State4 {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct State {
  cost: u32,
  cur:  Point,
  keys: u32,
}

impl Ord for State {
  fn cmp(&self, other: &Self) -> Ordering {
    (other.cost + other.keys.count_zeros())
      .cmp(&(self.cost + self.keys.count_zeros()))
      .then_with(|| (self.cur.x + self.cur.y).cmp(&(other.cur.x + other.cur.y)))
  }
}

impl PartialOrd for State {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

impl State {
  fn successors(&self, spaces: &HashMap<Point, Tile>) -> Vec<State> {
    self
      .cur
      .neighbors()
      .iter()
      .map(|p| match spaces.get(&p)? {
        Tile::Space | Tile::Start => Some(State { cost: self.cost + 1, cur: *p, keys: self.keys }),
        Tile::Key(k) => Some(State { cost: self.cost + 1, cur: *p, keys: self.keys | k }),
        Tile::Door(d) =>
          if self.keys & d != 0 {
            Some(State { cost: self.cost + 1, cur: *p, keys: self.keys })
          } else {
            None
          },
      })
      .filter(Option::is_some)
      .map(Option::unwrap)
      .collect()
  }

  fn reachable_keys(
    &self, spaces: &HashMap<Point, Tile>, seen: &mut HashMap<Point, u32>,
    results: &mut HashMap<u32, State>,
  ) {
    if let Some(cost) = seen.get(&self.cur)
      && *cost <= self.cost
    {
      return;
    }
    seen.insert(self.cur, self.cost);
    for s in self.successors(spaces) {
      if s.keys != self.keys {
        results.insert(s.keys ^ self.keys, s);
      }
      s.reachable_keys(spaces, seen, results);
    }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Point {
  x: i32,
  y: i32,
}

impl Point {
  fn neighbors(&self) -> [Point; 4] {
    [
      Point { x: self.x, y: self.y - 1 },
      Point { x: self.x + 1, y: self.y },
      Point { x: self.x, y: self.y + 1 },
      Point { x: self.x - 1, y: self.y },
    ]
  }
}

pub fn main() -> ExitCode { runner::run_day::<Day18>() }

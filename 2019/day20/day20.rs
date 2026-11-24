// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 20
//! Read the puzzle at <https://adventofcode.com/2019/day/20>
//!
//! Input is a grid with `.` for open spaces, `#` for walls, two adjacent upper-case letters for
//! portals, and blank spaces for unreachable locations.  Topologically, this grid forms a toroid,
//! with portals on the inner side connected to portals on the outer side.  Portals `AA` and `ZZ`
//! are always on the outer ring.  Moving from one space to another, whether or not through a
//! portal, has a cost of 1.  In part 1, the answer is the lowest cost to move from `AA` to `ZZ`.
//! In part 2, the toroid is recursive, with inner portals on level `N` connecting to outer portals
//! on level `N+1`; moving through outer portals on level 0 is not allowed.

mod runner;

use Neighbor::*;
use runner::Day;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::process::ExitCode;

pub struct Day20 {}

impl Day for Day20 {
  fn part1(lines: &[&str]) -> String {
    let board = parse_input(lines).simplify();
    let mut pq = BinaryHeap::new();
    pq.push(State { cost: 0, cur: board.start, level: 0 });
    let mut visited: HashMap<Point, usize> = HashMap::new();
    while let Some(state) = pq.pop() {
      if state.cur == board.end {
        return state.cost.to_string();
      }
      if let Some(&cost) = visited.get(&state.cur)
        && cost <= state.cost
      {
        continue;
      }
      visited.insert(state.cur, state.cost);
      for &(n, cost) in board.neighbors.get(&state.cur).unwrap().iter() {
        match n {
          Same(p) | Inner(p) | Outer(p) =>
            pq.push(State { cost: state.cost + cost, cur: p, level: 0 }),
        }
      }
    }
    String::from("no path found")
  }

  fn part2(lines: &[&str]) -> String {
    let board = parse_input(lines).simplify();
    let mut pq = BinaryHeap::new();
    // run from end to start because example 2 recurses infinitely if starting at AA but quickly
    // finds it's stuck with only outer portals if starting at ZZ
    pq.push(State { cost: 0, cur: board.end, level: 0 });
    let mut visited: HashMap<(Point, usize), usize> = HashMap::new();
    while let Some(state) = pq.pop() {
      if state.level == 0 && state.cur == board.start {
        return state.cost.to_string();
      }
      if let Some(&cost) = visited.get(&(state.cur, state.level))
        && cost <= state.cost
      {
        continue;
      }
      visited.insert((state.cur, state.level), state.cost);
      for &(n, cost) in board.neighbors.get(&state.cur).unwrap().iter() {
        match n {
          Same(p) => pq.push(State { cost: state.cost + cost, cur: p, level: state.level }),
          Inner(p) => pq.push(State { cost: state.cost + cost, cur: p, level: state.level + 1 }),
          Outer(p) if state.level > 0 =>
            pq.push(State { cost: state.cost + cost, cur: p, level: state.level - 1 }),
          Outer(_) => (),
        }
      }
    }
    String::from("no path found")
  }

  fn day_name() -> &'static str { "Day20" }
}

type Point = (usize, usize);

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq, PartialOrd, Ord)]
enum Neighbor {
  Same(Point),
  Inner(Point),
  Outer(Point),
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct NeighborState {
  cost: usize,
  cur:  Point,
}

impl Ord for NeighborState {
  fn cmp(&self, other: &Self) -> Ordering {
    other
      .cost
      .cmp(&(self.cost))
      .then_with(|| (self.cur.0 + self.cur.1).cmp(&(other.cur.0 + other.cur.1)))
  }
}

impl PartialOrd for NeighborState {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

#[derive(Debug)]
struct Board {
  neighbors: HashMap<Point, Vec<(Neighbor, usize)>>,
  portals:   HashMap<Point, String>,
  start:     Point,
  end:       Point,
}

impl Board {
  fn simplify(&self) -> Self {
    let mut neighbors: HashMap<Point, Vec<(Neighbor, usize)>> = HashMap::new();
    for &p in self.portals.keys() {
      let mut pns = Vec::new();
      let mut pq = BinaryHeap::new();
      pq.push(NeighborState { cost: 0, cur: p });
      let mut visited: HashMap<Point, usize> = HashMap::new();
      while let Some(state) = pq.pop() {
        if let Some(&cost) = visited.get(&state.cur)
          && cost <= state.cost
        {
          continue;
        }
        visited.insert(state.cur, state.cost);
        if self.portals.contains_key(&state.cur) {
          pns.push((Same(state.cur), state.cost));
        }
        for &(n, cost) in self.neighbors.get(&state.cur).unwrap().iter() {
          match n {
            Inner(_) | Outer(_) =>
              if state.cur == p {
                pns.push((n, cost))
              },
            Same(q) => pq.push(NeighborState { cost: state.cost + cost, cur: q }),
          }
        }
      }
      neighbors.insert(p, pns);
    }
    Board { neighbors, portals: self.portals.clone(), start: self.start, end: self.end }
  }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct State {
  cost:  usize,
  cur:   Point,
  level: usize,
}

impl Ord for State {
  fn cmp(&self, other: &Self) -> Ordering {
    other
      .cost
      .cmp(&(self.cost))
      .then_with(|| other.level.cmp(&(self.level)))
      .then_with(|| (self.cur.0 + self.cur.1).cmp(&(other.cur.0 + other.cur.1)))
  }
}

impl PartialOrd for State {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

fn parse_input(lines: &[&str]) -> Board {
  let y_inner = 4..lines.len() - 4;
  let x_inner = 4..lines.iter().map(|l| l.len()).max().unwrap() - 4;
  let charlines: Vec<Vec<char>> = lines.iter().map(|l| l.chars().collect()).collect();
  let mut board = Board {
    neighbors: HashMap::new(),
    portals:   HashMap::new(),
    start:     (0, 0),
    end:       (0, 0),
  };
  let mut portals = HashMap::new();
  for (y, line) in charlines.iter().enumerate() {
    for (x, &c) in line.iter().enumerate() {
      if c == '.' {
        let p: Point = (x, y);
        let mut adjacent: Vec<(Neighbor, usize)> = Vec::new();
        let mut portal = String::new();
        match charlines[y - 1][x] {
          '.' => {
            adjacent.push((Same((x, y - 1)), 1));
          }
          c if c.is_ascii_uppercase() => {
            portal.push(charlines[y - 2][x]);
            portal.push(charlines[y - 1][x]);
          }
          _ => {}
        }
        match charlines[y + 1][x] {
          '.' => {
            adjacent.push((Same((x, y + 1)), 1));
          }
          c if c.is_ascii_uppercase() => {
            portal.push(charlines[y + 1][x]);
            portal.push(charlines[y + 2][x]);
          }
          _ => {}
        }
        match charlines[y][x - 1] {
          '.' => {
            adjacent.push((Same((x - 1, y)), 1));
          }
          c if c.is_ascii_uppercase() => {
            portal.push(charlines[y][x - 2]);
            portal.push(charlines[y][x - 1]);
          }
          _ => {}
        }
        match charlines[y][x + 1] {
          '.' => {
            adjacent.push((Same((x + 1, y)), 1));
          }
          c if c.is_ascii_uppercase() => {
            portal.push(charlines[y][x + 1]);
            portal.push(charlines[y][x + 2]);
          }
          _ => {}
        }
        if !portal.is_empty() {
          board.portals.insert(p, portal.clone());
          if portal == "AA" {
            board.start = p;
          }
          if portal == "ZZ" {
            board.end = p;
          }
          match portals.get(&portal) {
            Some(other) => {
              let (me, them) = if x_inner.contains(&p.0) && y_inner.contains(&p.1) {
                (Outer(p), Inner(*other))
              } else {
                (Inner(p), Outer(*other))
              };
              adjacent.push((them, 1));
              board.neighbors.get_mut(other).unwrap().push((me, 1));
            }
            None => {
              portals.insert(portal, p);
            }
          }
        }
        board.neighbors.insert(p, adjacent);
      }
    }
  }
  board
}

pub fn main() -> ExitCode { runner::run_day::<Day20>() }

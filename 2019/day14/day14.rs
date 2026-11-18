// Copyright 2026 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

//! # Advent of Code 2019 day 14
//! Read the puzzle at <https://adventofcode.com/2019/day/14>
//!
//! Input is lines like `12 FOO, 34 BAR => 56 BAZ` describing a recipe for making some amount of
//! a substance from amounts of other substances.  Each substance only has one recipe which can
//! produce it, except `ORE` which makes up every leaf node in a recipe tree.  `FUEL` is the root
//! of the tree.  When producing a substance, some amount of ingredients will be left over, and can
//! be used in other recipes.  In part 1, compute the amount of `ORE` needed to produce 1 `FUEL`.
//! In part 2, compute the amount of `FUEL` that could be produced from one trillion `ORE`.

mod runner;

use runner::Day;
use std::collections::{HashMap, VecDeque};
use std::process::ExitCode;

pub struct Day14 {}

impl Day for Day14 {
  fn part1(lines: &[&str]) -> String {
    let parsed: Vec<_> = lines.into_iter().map(|line| parse_line(line)).collect();
    let recipes: HashMap<_, _> = parsed.iter().map(|r| (r.target.substance, r)).collect();
    ore_for(Ingredient { amount: 1, substance: "FUEL" }, &recipes).to_string()
  }

  fn part2(lines: &[&str]) -> String {
    let trillion = 1_000_000_000_000;
    let parsed: Vec<_> = lines.into_iter().map(|line| parse_line(line)).collect();
    let recipes: HashMap<_, _> = parsed.iter().map(|r| (r.target.substance, r)).collect();
    let mut fuel = Ingredient { amount: 1, substance: "FUEL" };
    let for_one = ore_for(fuel, &recipes);
    // it's tempting to look for a lower upper bound, but trillion could be the answer for
    // trillion ORE => trillion FOO | 1 FOO => 1 FUEL
    let mut max = trillion;
    let mut min = trillion / for_one;
    while max - min > 1 {
      fuel.amount = min + (max - min) / 2;
      let ore = ore_for(fuel, &recipes);
      if ore > trillion {
        max = fuel.amount;
      } else {
        min = fuel.amount;
      }
    }
    min.to_string()
  }

  fn day_name() -> &'static str { "Day14" }
}

fn ore_for(desired: Ingredient, recipes: &HashMap<&str, &Recipe>) -> u64 {
  let ore_recipe =
    Recipe { target: Ingredient { amount: 1, substance: "ORE" }, ingredients: Vec::new() };
  let mut have: HashMap<&str, u64> = HashMap::new();
  let mut ore = 0;
  let mut q = VecDeque::new();
  q.push_back(desired);
  while let Some(next) = q.pop_back() {
    let mut need = next.amount;
    if let Some(&avail) = have.get(next.substance)
      && avail > 0
    {
      let used = need.min(avail);
      have.insert(next.substance, avail - used);
      need -= used;
    }
    if need == 0 {
      continue;
    }
    if next.substance == "ORE" {
      ore += next.amount;
    }
    let default = &&ore_recipe;
    let recipe = recipes.get(&next.substance).unwrap_or(default);
    let amount = recipe.target.amount;
    let times = (need + amount - 1) / amount; // TODO div_ceil when int_roundings is stable
    let made = amount * times;
    have.insert(next.substance, made - need);
    for i in recipe.ingredients.iter() {
      q.push_back(Ingredient { amount: i.amount * times, substance: i.substance });
    }
  }
  ore
}

fn parse_line(line: &str) -> Recipe<'_> {
  let leftright: Vec<_> = line.split(" => ").collect();
  let target = Ingredient::try_from(leftright[1]).unwrap();
  let components = leftright[0].split(", ").map(|s| Ingredient::try_from(s).unwrap()).collect();
  Recipe { target, ingredients: components }
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
struct Ingredient<'a> {
  amount:    u64,
  substance: &'a str,
}

impl<'a> From<&'a str> for Ingredient<'a> {
  fn from(s: &'a str) -> Self {
    let parts: Vec<_> = s.split(' ').collect();
    let amount = parts[0].parse().unwrap();
    Ingredient { amount, substance: parts[1] }
  }
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct Recipe<'a> {
  target:      Ingredient<'a>,
  ingredients: Vec<Ingredient<'a>>,
}

pub fn main() -> ExitCode { runner::run_day::<Day14>() }

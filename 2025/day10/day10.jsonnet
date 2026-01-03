// Copyright 2025 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2025 day 10
// Read the puzzle at https://adventofcode.com/2025/day/10
// Input is a light pattern in square brackets, a series of button lists in
// parentheses, and a list of target joltage levels in curly braces, e.g.
// [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
// Button numbers are all 0 to 9, . means off # means on.
// In part 1, buttons toggle lights of the corresponding index, the answer is
// the minimum number of button presses to reach the desired pattern.
// In part 2, buttons increase the joltage level at each given index, the
// answer is the minimum number of button presses to reach the desired levels.

// NOTE: On the actual input file, the default jsonnet stack may be too small.
// If you see "<std>:231:22-42 thunk from <thunk from <function <build>>>" in
// stack traces, try something like "jsonnet -s 3000 -t 64 ..." for a really
// big stack size.  Evan though tailstrict is used in the build() function
// inside std.slice, it somehow creates a pretty huge stack to resolve the
// recursively constructed stack in the bifurcate function.

// std.jsonnet functions that might not be available
// added in 0.21.0
local contains(arr, elem) = std.any([e == elem for e in arr]);
// added in 0.21.0
local minArray(arr, keyF=std.id, onEmpty=error 'Expected at least one element in array. Got none') =
  local minVal = arr[0];
  local minFn(a, b) = if std.__compare(keyF(a), keyF(b)) > 0 then b else a;
  std.foldl(minFn, arr, minVal);

local indexRange(a) = std.range(0, std.length(a) - 1);

local parseButton(word) = std.map(std.parseInt, std.split(std.stripChars(word, '()'), ','));

local parseLine(line) = {
  local words = std.split(line, ' '),
  local buts = [parseButton(b) for b in words[1:std.length(words) - 1]],
  desired: std.stripChars(words[0], '[]'),
  buttons: std.map(
    function(b) std.join('', [if contains(b, i) then '#' else '.' for i in indexRange(self.desired)]),
    buts
  ),
  levels: std.map(std.parseInt, std.split(std.stripChars(words[std.length(words) - 1], '{}'), ',')),
};

local stringXor(a, b) =
  std.join('', [if std.xor(a[i] == '#', b[i] == '#') then '#' else '.' for i in indexRange(a)]);

local buttonCombinations(buttons, bindex, cache) =
  if bindex == std.length(buttons) then cache
  else
    buttonCombinations(buttons, bindex + 1, cache + {
      [stringXor(buttons[bindex], k)]+: [a + [bindex] for a in cache[k]]
      for k in std.objectFields(cache)
    });

// Support functions for part 2
local HUGE = 1000000;  // number of presses to reach an impossible state

local levelParity(js) = std.join('', [if x % 2 == 0 then '.' else '#' for x in js]);

local subtractButtons(machine, levels, buttons) =
  [
    levels[i] - std.length(std.filter(function(bi) machine.buttons[bi][i] == '#', buttons))
    for i in indexRange(levels)
  ];

local notNegative(levels) = std.all([l >= 0 for l in levels]);

local halfLevel(js) = [std.floor(x / 2) for x in js];

// Cribbed from the excellent tutorial by u/tenthmascot at
// reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/
local bifurcate(machine, combos, cache, stack) =
  if std.length(stack) == 0 then cache[std.toString(machine.levels)]
  else
    local cur = stack[0];
    local parity = levelParity(cur.levels);
    local ways = if std.objectHas(combos, parity) then std.uniq(std.sort(combos[parity])) else [];
    local halves = [{
      levels: halfLevel(subtractButtons(machine, cur.levels, w) tailstrict),
      key: std.toString(self.levels),
      add: std.length(w),
    } for w in ways if notNegative(subtractButtons(machine, cur.levels, w) tailstrict)];
    if std.all([std.objectHas(cache, h.key) for h in halves]) then
      local vals = [cache[h.key] * 2 + h.add for h in halves];
      local best = if vals == [] then HUGE else minArray(vals);
      local newcache = cache { [cur.key]: best };
      bifurcate(machine, combos, newcache, stack[1:]) tailstrict
    else
      local next = [{ key: h.key, levels: h.levels } for h in halves];
      bifurcate(machine, combos, cache, next + stack) tailstrict;

local solvePart2(machine, combos) =
  local cache = { [std.toString([0 for i in indexRange(machine.levels)])]: 0 };
  bifurcate(machine, combos, cache, [{ levels: machine.levels, key: std.toString(machine.levels) }]);

function(lines) {
  local machines = std.map(parseLine, lines),
  local solutions = [{
    local combos = buttonCombinations(m.buttons, 0, { [stringXor(m.desired, m.desired)]: [[]] }),
    part1: std.length(minArray(combos[m.desired], std.length)),
    part2: solvePart2(m, combos),
  } for m in machines],

  dayname: 'day10',
  part1: std.sum([s.part1 for s in solutions]),
  part2: std.sum([s.part2 for s in solutions]),
}

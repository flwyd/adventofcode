// Copyright 2025 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code runner for Jsonnet language.  dayX.jsonnet should define a
// function which takes an array of lines and returns an object with part1,
// part2, and daynum properties.  That script and an input file are then passed
// to the runner with an invocation like
// jsonnet -S runner.jsonnet --tla-code 'verbose=true' \
//   --tla-code 'solve=import "dayX/dayX.jsonnet"' \
//   --tla-code 'files=[
//   {name: "input.example.txt", content=importstr "input.example.txt", expected=importstr "input.example.expected"},
//   {name: "input.actual.txt", content=importstr "input.actual.txt", expected=importstr "input.actual.expected"},
//   ]'

// std.trim added in 0.21.0
local trim(str) = std.stripChars(str, ' \t\n\f\r\u0085 ');

local parseExpected(text) = {
  [std.splitLimit(line, ':', 1)[0]]: trim(std.splitLimit(line, ':', 1)[1])
  for line in std.split(std.rstripChars(text, '\n'), '\n')
};

local formatResult(part, actual, expected) =
  local signs = { success: '✅', fail: '❌', unknown: '❓', todo: '❗' };
  local outcome =
    if (std.toString(actual) == expected) then 'success'
    else if (actual == 'TODO') then 'todo'
    else if (expected == '') then 'unknown'
    else 'fail';
  local message = {
    success: 'got ' + actual,
    todo: if (expected == '') then 'implement it' else 'implement it, wanted ' + expected,
    unknown: 'got ' + actual,
    fail: 'got %s, wanted %s' % [actual, expected],
  }[outcome];
  std.join(' ', [signs[outcome], std.asciiUpper(outcome), message]);

local solveFile(solve, file, verbose=false) = {
  lines: std.split(std.rstripChars(file.content, '\n'), '\n'),
  expected: if (std.objectHas(file, 'expected'))
  then parseExpected(file.expected)
  else { part1: '', part2: '' },
  solved: solve(self.lines),
  prolog: if (verbose)
  then std.trace(
    'Running %s on %s (%d lines)' % [self.solved.dayname, file.name, std.length(self.lines)], ''
  ) else '',
  epilog: if (verbose)
  then std.trace(formatResult('part1', self.solved.part1, self.expected.part1), '')
       + std.trace(formatResult('part2', self.solved.part2, self.expected.part2), '')
       + std.trace(std.repeat('=', 40), '')
  else '',
  parts: ['part1: ' + self.solved.part1, 'part2: ' + self.solved.part2],
  output: self.prolog + std.join('\n', self.parts) + self.epilog,
};

function(solve, files, verbose=false)
  std.join('\n', std.map(function(f) solveFile(solve, f, verbose).output, files))

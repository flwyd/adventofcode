// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Jsonnet structure for solution.  Transform input files to a structure like
// local day4 = import 'day4.jsonnet';
// day4 {
//   cards: [
//     self.card(1, [8, 6, 7], [8, 6, 7, 5, 3, 0, 9]),
//     // etc.
//   ]
// }.result.asPlainText
// And run with jsonnet -S
{
  local outer = self,
  cards: error 'Must provide an array of cards',
  card(num, winners, have):: {
    copies: 1 + std.sum(std.filterMap(function(c) std.setMember(num, c.affects), function(c) c.copies, outer.cards)),
    affects: std.makeArray(self.wins, function(i) num + i + 1),
    wins: std.length(std.setInter(std.set(winners), std.set(have))),
    score: if self.wins == 0 then 0 else 1 << (self.wins - 1),
  },
  result: {
    part1: std.sum(std.map(function(c) c.score, outer.cards)),
    part2: std.sum(std.map(function(c) c.copies, outer.cards)),
    asPlainText: std.join('\n', ['part1: ' + self.part1, 'part2: ' + self.part2]),
  },
}

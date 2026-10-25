// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Input is a list like "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53"
// where the numbers between colon and pipe are winning numbers and the numbers
// after the pipe are numbers you have on your card.  In part 1 the score for a
// card is 0 for no winners, or two to the power of the number of winners minus
// one.  In part 2, duplicate the following N cards when the current card has N
// winners and the answer is the total number of cards, including duplicates
// and originals.

local parseInts(str) =
  [std.parseInt(std.trim(x)) for x in std.split(str, ' ') if std.trim(x) != ''];

function(lines) {
  local outer = self,
  local parseCard(line) =
    local num = std.parseInt(std.lstripChars(std.split(line, ':')[0], 'Card '));
    local winners = parseInts(std.split(std.split(line, ':')[1], '|')[0]);
    local have = parseInts(std.split(std.split(line, ':')[1], '|')[1]);
    card(num, winners, have),
  local card(num, winners, have) = {
    copies: 1 + std.sum(
      [c.copies for c in outer.cards if std.setMember(num, c.affects)]
    ),
    affects: std.makeArray(self.wins, function(i) num + i + 1),
    wins: std.length(std.setInter(std.set(winners), std.set(have))),
    score: if self.wins == 0 then 0 else 1 << (self.wins - 1),
  },

  cards: std.map(parseCard, lines),
  part1: std.sum(std.map(function(c) c.score, self.cards)),
  part2: std.sum(std.map(function(c) c.copies, self.cards)),
  dayname: 'day4',
}

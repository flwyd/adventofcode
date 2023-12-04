#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 4
[Read the puzzle](https://adventofcode.com/2023/day/4)

Input is a list like "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53" where the numbers between
colon and pipe are winning numbers and the numbers after the pipe are numbers you have on your card.
In part 1 the score for a card is 0 for no winners and two to the power of the numebr of winners
minus one.  In part 2, duplicate the following N cards when the current card has N winners and the
answer is the total number of cards, including duplicates and originals.
"""
module Day4

function part1(lines)
  map(parseinput(lines)) do card
    count = length(card[2] ∩ card[3])
    count == 0 ? 0 : 2^(count - 1)
  end |> sum
end

function part2(lines)
  copies = ones(Int, length(lines))
  for (card, wins, have) in parseinput(lines)
    count = length(wins ∩ have)
    copies[(card + 1):(card + count)] .+= copies[card]
  end
  sum(copies)
end

function parseinput(lines)
  map(lines) do line
    card, wins, have = split(line, [':', '|'])
    (parse(Int, chopprefix(card, "Card")), parse.(Int, split(wins)), parse.(Int, split(have)))
  end
end

include("../Runner.jl")
@run_if_main
end

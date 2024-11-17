#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 7
[Read the puzzle](https://adventofcode.com/2023/day/7)

Input is poker-style hands and bid values.  Hands are ranked with five-of-a-kind > four-of-a-kind >
full house > three-of-a-kind > two-pair > pair > high card.  Within a type, hands are scored by the
order of cards, so the full house 52525 scores higher than the full house 25255.
All inputs are ordered by their rank (1 is the worst hand), then position * bid are added.
Part 2 changes J from Jack to Joker.  Joker takes on the identity of any card for ranking but when
comparing within a rank it is the lowest card (less than 2).
"""
module Day7

primitive type Card <: AbstractChar 32 end
Card(c::Char) = reinterpret(Card, c)
Char(c::Card) = reinterpret(Char, c)
Base.codepoint(c::Card) = codepoint(Char(c))

const JOKER = Card('J')
# Joker becomes 0
const ORDER = "023456789TJQKA"
Base.isless(a::Card, b::Card) = findfirst(a, ORDER) < findfirst(b, ORDER)

struct Hand
  cards::Vector{Card}
  bid::Int
  jokers::Bool
end

# Returns a list of card occurrence counts sorted descending, e.g. [3, 2] for a full house
function handtype(h::Hand)
  cards = h.jokers ? optimize_jokers(h.cards) : h.cards
  sort([count(==(i), cards) for i in unique(cards)]; rev=true)
end

function Base.isless(a::Hand, b::Hand)
  haa, hab = handtype(a), handtype(b)
  if haa == hab
    a.jokers ? jokers_for_scoring(a.cards) < jokers_for_scoring(b.cards) : a.cards < b.cards
  else
    haa < hab
  end
end

function optimize_jokers(cards)
  jokers = count(==(JOKER), cards)
  if jokers == 5
    return cards
  end
  nonjokers = [(count(==(i), cards), i) for i in filter(!=(JOKER), cards)]
  most = first(sort(nonjokers, rev=true))
  replace(cards, JOKER => most[2])
end

jokers_for_scoring(cards) = replace(cards, JOKER => Card('0'))

part1(lines) = solution(lines, false)
part2(lines) = solution(lines, true)
function solution(lines, jokers)
  sum(map(((i, h),) -> i * h.bid, enumerate(sort(parseinput(lines, jokers)))))
end

function parseinput(lines, jokers)
  map(lines) do line
    cards, bid = split(line)
    Hand([Card(c) for c in cards], parse(Int, bid), jokers)
  end
end

include("../Runner.jl")
@run_if_main
end

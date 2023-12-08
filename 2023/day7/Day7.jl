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

# Joker becomes 0
const ORDER = "023456789TJQKA"

struct Hand
  cards::AbstractString
  bid::Int
  value::Tuple{Vector{Int}, Vector{Int}}
  function Hand(cards, bid, jokers)
    cards = jokers ? replace(cards, 'J' => '0') : cards
    mod = jokers ? optimize_jokers(cards) : cards
    handtype = sort([count(==(i), mod) for i in unique(mod)]; rev=true) # [3, 2] is a full house
    tiebreaker = collect(findfirst(c, ORDER) for c in cards)
    new(cards, bid, (handtype, tiebreaker))
  end
end

Base.isless(a::Hand, b::Hand) = a.value < b.value

function optimize_jokers(cards)
  jokers = count(==('0'), cards)
  if jokers == 5
    return cards
  end
  nonjokers = [(count(==(i), cards), i) for i in filter(!=('0'), cards)]
  _, most = first(sort(nonjokers, rev=true))
  replace(cards, '0' => most)
end

part1(lines) = solution(lines, false)
part2(lines) = solution(lines, true)

function solution(lines, jokers)
  sortedhands = sort(parseinput(lines, jokers))
  sum(map(ib -> first(ib) * last(ib), enumerate(map(h -> h.bid, sortedhands))))
end

function parseinput(lines, jokers)
  map(lines) do line
    cards, bid = split(line)
    Hand(cards, parse(Int, bid), jokers)
  end
end

include("../Runner.jl")
@run_if_main
end

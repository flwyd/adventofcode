#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 7
[Read the puzzle](https://adventofcode.com/2023/day/7)
"""
module Day7

struct Card
  value::Char
end

const ORDER = "023456789TJQKA"
function Base.isless(a::Card, b::Card)
  isless(findfirst(a.value, ORDER), findfirst(b.value, ORDER))
end

struct Hand
  cards::Vector{Card}
  bid::Int
  jokers::Bool
end

function handtype(h::Hand)
  cards = h.jokers ? optimize_jokers(h.cards) : h.cards
  sort([count(==(i), cards) for i in unique(cards)]; rev=true) |> filter(!=(1))
end

function Base.isless(a::Hand, b::Hand)
  haa = handtype(a)
  hab = handtype(b)
  if haa == hab
    if a.jokers
      replace(a.cards, Card('J') => Card('0')) < replace(b.cards, Card('J') => Card('0'))
    else
      a.cards < b.cards
    end
  else
    haa < hab
  end
end

function optimize_jokers(cards)
  jokers = count(==(Card('J')), cards)
  if jokers == 5
    return cards
  end
  nonjokers = [(count(==(i), cards), i) for i in filter(!=(Card('J')), cards)]
  most = first(sort(nonjokers, rev=true))
  replace(cards, Card('J') => most[2])
end

function part1(lines)
  input = parseinput(lines, false)
  sortedhands = sort(input)
  sum(map(ib -> first(ib) * last(ib), enumerate(map(h -> h.bid, sortedhands))))
end

function part2(lines)
  input = parseinput(lines, true)
  sortedhands = sort(input)
  sum(map(ib -> first(ib) * last(ib), enumerate(map(h -> h.bid, sortedhands))))
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

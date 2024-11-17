#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 20
[Read the puzzle](https://adventofcode.com/2023/day/20)

Input is logic gates and outputs with `%` before the gate name indicating a flip-flop that changes
state and sends its new state if the incoming pulse is low; `&` indicating a conjunction which
remembers the sate of all inputs and sends low when it receives a pulse and all remembered inputs
are high and sends high when receiving a pulse otherwise; and a `broadcaster` node without a sigil
which sends received pulses to all outputs.  One gate is mentioned in the outputs lists but doesn't
have any outputs itself (except in the first example).  There's a button that sends a low pulse to
`broadcaster`.  Part 1 is the number of total low pulses times the number of high pulses sent by
pushing the button one thousand times.  Part 2 is the number of button pushes required before the
sink gate receives a low pulse.
"""
module Day20

function part1(lines)
  gates = parseinput(lines)
  highs = lows = 0
  for _ in 1:1000
    h, l = push_the_button(gates)
    highs += h
    lows += l
  end
  highs * lows
end

function part2(lines)
  gates = parseinput(lines)
  sinks = filter(g -> g isa Broadcaster && isempty(g.outputs), collect(values(gates)))
  if isempty(sinks)
    return 0  # first example isn't relevant to part 2
  end
  sink = Iterators.only(sinks).name
  firsthigh = Dict{AbstractString, Int}()
  # TODO find a way to determine these from input
  relevant_conjunctions = ("rz", "lf", "br", "fk")
  for i in 1:typemax(Int)
    pending = [Pulse(false, "", "broadcaster")]
    while !isempty(pending)
      pulse = popfirst!(pending)
      if !pulse.high && pulse.dest == sink
        return i
      end
      if pulse.high && pulse.source ∈ relevant_conjunctions
        firsthigh[pulse.source] = i
      end
      receive(gates[pulse.dest], pulse, gates, pending)
    end
    if length(firsthigh) == length(relevant_conjunctions)
      return prod(values(firsthigh))
    end
  end
end

mutable struct FlipFlop
  name::AbstractString
  high::Bool
  outputs::Vector{AbstractString}
end
mutable struct Conjunction
  name::AbstractString
  inputs::Dict{AbstractString, Bool}
  outputs::Vector{AbstractString}
end
mutable struct Broadcaster
  name::AbstractString
  outputs::Vector{AbstractString}
end
struct Pulse
  high::Bool
  source::AbstractString
  dest::AbstractString
end

function receive(gate::Broadcaster, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
  for out in gate.outputs
    push!(pending, Pulse(pulse.high, gate.name, out))
  end
end

function receive(gate::FlipFlop, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
  if !pulse.high
    gate.high = !gate.high
    for out in gate.outputs
      push!(pending, Pulse(gate.high, gate.name, out))
    end
  end
end

function receive(gate::Conjunction, pulse::Pulse, gates::Dict, pending::Vector{Pulse})
  gate.inputs[pulse.source] = pulse.high
  high = !all(values(gate.inputs))
  for out in gate.outputs
    push!(pending, Pulse(high, gate.name, out))
  end
end

function push_the_button(gates)
  pending = [Pulse(false, "", "broadcaster")]
  highs, lows = 0, 0
  while !isempty(pending)
    pulse = popfirst!(pending)
    pulse.high ? highs += 1 : lows += 1
    receive(gates[pulse.dest], pulse, gates, pending)
  end
  highs, lows
end

function parseinput(lines)
  outputs = Dict{AbstractString, Vector{AbstractString}}()
  inputs = Dict{AbstractString, Vector{AbstractString}}()
  flipflops = Set{AbstractString}()
  conjunctions = Set{AbstractString}()
  broadcasters = Set{AbstractString}()
  for line in lines
    gate, outs = split(line, " -> ")
    name = gate
    if startswith(gate, '%')
      name = gate[2:end]
      push!(flipflops, name)
    elseif startswith(gate, '&')
      name = gate[2:end]
      push!(conjunctions, name)
    else
      push!(broadcasters, name)
    end
    outputs[name] = split(outs, ", ")
    for o in outputs[name]
      if !haskey(inputs, o)
        inputs[o] = AbstractString[]
      end
      push!(inputs[o], name)
    end
  end
  for name in keys(inputs)
    if !haskey(outputs, name)
      outputs[name] = AbstractString[]
      push!(broadcasters, name)
    end
  end
  gates = Dict()
  for name in flipflops
    gates[name] = FlipFlop(name, false, outputs[name])
  end
  for name in conjunctions
    gates[name] = Conjunction(name, Dict(i => false for i in inputs[name]), outputs[name])
  end
  for name in broadcasters
    gates[name] = Broadcaster(name, outputs[name])
  end
  gates
end

include("../Runner.jl")
@run_if_main
end

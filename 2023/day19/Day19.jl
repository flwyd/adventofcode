#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

"""# Advent of Code 2023 day 19
[Read the puzzle](https://adventofcode.com/2023/day/19)

Input is a series of workflows followed by a series of part speifications.  Each workflow looks
like `name{x>123:foo,a<456:bar,baz}` with the condition subjects in `xmas` and the value after
the colon a workflow to follow if that condition matches.  Labels without a condition are run if
no previous condition matches.  Part specifications give values for `xmas` properties.  The `A`
workflow accepts the part, the `R` workflow rejects the part.  Workflows start with `in`.

Part 1 is the sum of sums of part properties which are accepted.
Part 2 ignores the input part and says that each `xmas` property can range from 1 to 4000.
The part 2 answer is the number of parts in those ranges which would be accepted.
"""
module Day19

# TODO clean up code

function part1(lines)
  workflows, parts = parseinput(lines)
  map(p -> evaluate(workflows, p) ? score(p) : 0, parts) |> sum
end

function part2(lines)
  workflows, _ = parseinput(lines)
  numaccepted(workflows, "in", PartRange(1:4000, 1:4000, 1:4000, 1:4000))
end

struct Part
  x::Int
  m::Int
  a::Int
  s::Int
end

struct PartRange
  x::UnitRange{Int}
  m::UnitRange{Int}
  a::UnitRange{Int}
  s::UnitRange{Int}
end

struct Instruction
  var::Symbol
  op::Symbol
  val::Int
end

struct Workflow
  instructions::Vector{Pair{Instruction, String}}
  steps::Vector{Pair{Function, String}}
end

function splitrange(pr::PartRange, var::Symbol, lessthan::Int)
  cur = getproperty(pr, var)
  low = first(cur):(lessthan - 1)
  high = lessthan:last(cur)
  # TODO non-silly way to do this
  if var == :x
    PartRange(low, pr.m, pr.a, pr.s), PartRange(high, pr.m, pr.a, pr.s)
  elseif var == :m
    PartRange(pr.x, low, pr.a, pr.s), PartRange(pr.x, high, pr.a, pr.s)
  elseif var == :a
    PartRange(pr.x, pr.m, low, pr.s), PartRange(pr.x, pr.m, high, pr.s)
  elseif var == :s
    PartRange(pr.x, pr.m, pr.a, low), PartRange(pr.x, pr.m, pr.a, high)
  else
    error("Bad symbol $var")
  end
end

function numaccepted(workflows, name, pr)
  if any(isempty, (pr.x, pr.m, pr.a, pr.s))
    return 0
  end
  if name == "R"
    return 0
  end
  if name == "A"
    return prod(length, (pr.x, pr.m, pr.a, pr.s))
  end
  wf = workflows[name]
  accepted = 0
  cur = pr
  for (i, dest) in wf.instructions
    if i.op == :_
      accepted += numaccepted(workflows, dest, cur)
    elseif i.op == :<
      low, high = splitrange(cur, i.var, i.val)
      accepted += numaccepted(workflows, dest, low)
      cur = high
    elseif i.op == :>
      low, high = splitrange(cur, i.var, i.val + 1)
      accepted += numaccepted(workflows, dest, high)
      cur = low
    else
      error("Bad op :$i")
    end
  end
  accepted
end

alwaystrue(_::Part) = true

topredicate(i::Instruction) =
  if i.op == :_
    alwaystrue
  else
    o = i.op == :< ? <(i.val) : >(i.val)
    p -> o(getproperty(p, i.var))
  end

function parseinput(lines)
  combos = Set{AbstractString}()
  workflowlines = Iterators.takewhile(!isempty, lines)
  workflows = Dict(map(workflowlines) do line
    name, content = split(line, ['{', '}']; keepempty=false)
    instructions = map(split(content, ",")) do chunk
      if ':' ∉ chunk
        Instruction(:_, :_, 0) => chunk
      else
        cond, dest = split(chunk, ':')
        push!(combos, cond)
        varstr, opstr, valstr = match(r"([xmas])([<>])(\d+)", cond).captures
        Instruction(Symbol(varstr), opstr == "<" ? :< : :>, parse(Int, valstr)) => dest
      end
    end
    name => Workflow(instructions, map(p -> topredicate(first(p)) => last(p), instructions))
  end)
  partlines = Iterators.dropwhile(!startswith("{"), lines)
  parts = map(partlines) do line
    x, m, a, s = parse.(Int, match(r"x=(\d+),m=(\d+),a=(\d+),s=(\d+)", line).captures)
    Part(x, m, a, s)
  end
  (workflows, parts)
end

function evaluate(flows, p::Part)
  name = "in"
  while true
    if name == "A"
      return true
    end
    if name == "R"
      return false
    end
    for (predicate, dest) in flows[name].steps
      if predicate(p)
        name = dest
        break
      end
    end
  end
end

score(p::Part) = p.x + p.m + p.a + p.s

include("../Runner.jl")
@run_if_main
end

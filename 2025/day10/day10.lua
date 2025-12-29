#!/usr/bin/env lua
-- Copyright 2025 Trevor Stone
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.

--[[ Advent of Code 2025 day 10
Read the puzzle at https://adventofcode.com/2025/day/10

Input is a light pattern in square brackets, a series of button lists in
parentheses, and a list of target joltages in curly braces, e.g.
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
Button numbers are all 0 to 9, . means off # means on.
In part 1, buttons toggle lights of the corresponding index, the answer is
the minimum number of button presses to reach the desired pattern.
In part 2, buttons increase the joltage level at each given index, the
answer is the minimum number of button presses to reach the desired levels.
]]--

require('runner')

local function parsemachine(line)
  local a, b, c = string.match(line, "[[]([.#]*)[]] (.*) [{]([0-9,]*)[}]")
  local m = {}
  m.width = #a
  m.pattern = 0
  for i = 1, m.width do
    if a:byte(i) == string.byte("#", 1) then
      m.pattern = m.pattern | (1 << (i-1))
    end
  end
  m.buttons = {}
  for w in b:gmatch("%S+") do
    local but = 0
    for x in w:gmatch("%d+") do
      but = but | (1 << tonumber(x))
    end
    table.insert(m.buttons, but)
  end
  m.levels = {}
  for n in c:gmatch("%d+") do
    table.insert(m.levels, tonumber(n))
  end
  return m
end

local function parseinput(lines)
  local machines = {}
  for i, l in ipairs(lines) do
    machines[i] = parsemachine(l)
  end
  return machines
end

local function countPart1(machine)
  local states = {0}
  local seen = {[0] = true}
  for p = 1, #machine.buttons do
    local subs = {}
    for _, s in pairs(states) do
      for _, b in pairs(machine.buttons) do
        local v = s ~ b
        if v == machine.pattern then return p end
        if seen[v] == nil then
          table.insert(subs, v)
          seen[v] = true
        end
      end
    end
    states = subs
  end
  error(string.format(
    "Did not match pattern %d after %d combinations of buttons",
    machine.pattern, #machine.buttons))
end

local Equation = {}
local EquationMeta = {__index = Equation}

function Equation.new(rhs)
  return setmetatable({first = 0, last = 0, rhs = rhs or 0}, EquationMeta)
end

function EquationMeta.__tostring(e)
  if e:empty() then return string.format("0 = %d", e.rhs) end
  local s = string.format("%dx%d", e:at(e.first), e.first)
  for i = e.first+1, e.last do
    local v = e:at(i)
    if v ~= 0 then
      local sign = "+"
      if v < 0 then sign = "-" end
      s = s .. string.format(" %s %dx%d", sign, math.abs(v), i)
    end
  end
  s = s .. string.format(" = %d", e.rhs)
  return s
end

function Equation.empty(e) return e.first == 0 end

function Equation.single(e) return e.first == e.last end

function Equation.at(e, idx) return e[idx] or 0 end

function Equation.set(e, idx, val)
  e[idx] = val
  if val ~= 0 then
    if e.first == 0 then
      e.first = idx
    else
      e.first = math.min(e.first, idx)
    end
    if e.last == 0 then
      e.last = idx
    else
      e.last = math.max(e.last, idx)
    end
  else
    if idx == e.last then
      for i = e.last, e.first, -1 do
        if e:at(i) ~= 0 then
          e.last = i
          break
        end
      end
    end
    if idx == e.first then
      for i = e.first, e.last do
        if e:at(i) ~= 0 then
          e.first = i
          break
        end
      end
      if idx == e.first then -- still
        e.first, e.last = 0, 0
      end
    end
  end
end

function Equation.clone(e)
  local f = Equation.new(e.rhs)
  for i = e.first, e.last do
    local v = e[i]
    if v then
      f:set(i, v)
    end
  end
  return f
end

function Equation.negate(e)
  local f = e:clone()
  f.rhs = -f.rhs
  for i = f.first, f.last do
    local v = f:at(i)
    if v ~= 0 then
      f:set(i, -v)
    end
  end
  return f
end

function Equation.add(e, eq, factor)
  factor = factor or 1
  local f = Equation.new(e.rhs + eq.rhs * factor)
  for i = math.min(e.first, eq.first), math.max(e.last, eq.last) do
    local v = e:at(i) + eq:at(i) * factor
    if v ~= 0 then
      f:set(i, v)
    end
  end
  return f
end

local EquationSystem = {}
local EquationSystemMeta = {__index = EquationSystem}

function EquationSystem.new(eqs)
  local s = {eqs = {}, cols = 0}
  setmetatable(s, EquationSystemMeta)
  if eqs ~= nil then
    for i, e in ipairs(eqs) do
      s.eqs[i] = e
      s.cols = math.max(s.cols, e.last)
    end
  end
  return s
end

function EquationSystemMeta.__tostring(s)
  local r = {}
  for _, e in ipairs(s.eqs) do
    table.insert(r, tostring(e))
  end
  return table.concat(r, "\n")
end

function EquationSystem.clone(s)
  local r = EquationSystem.new()
  r.cols = s.cols
  for i, e in ipairs(s.eqs) do
    r.eqs[i] = e:clone()
  end
  return r
end

function EquationSystem.swap(s, i, j)
  s.eqs[i], s.eqs[j] = s.eqs[j], s.eqs[i]
end

function EquationSystem.negate(s, i)
  s.eqs[i] = s.eqs[i]:negate()
end

function EquationSystem.add(s, i, j, factor)
  s.eqs[i] = s.eqs[i]:add(s.eqs[j], factor or 1)
end

-- Reduce s to an upper triangular diagonal matrix using only integer-safe row
-- operations; similar to transposing, computing Hermite normal form, and
-- transposing back.  The matrix for s does need not be square and rows may be
-- linearly dependent, so 0 values on the resulting diagonal are possible.
function EquationSystem.reduce(s)
  for row = 1, math.min(#s.eqs, s.cols) do
    ::considerSwaps::
    local e = s.eqs[row]
    local u = e:at(row)
    if u == 0 and e.first <= #s.eqs then
      for i = e.first, math.min(e.last, #s.eqs) do
        if e:at(i) ~= 0 and s.eqs[i]:at(i) == 0 then
          -- print(string.format("swap(%d, %d) [%s] [%s]", row, i, e, s.eqs[i]))
          s:swap(row, i)
          goto considerSwaps
        end
      end
    end
    for i = row+1, #s.eqs do
      local f = s.eqs[i]
      local v = f:at(row)
      if v ~= 0 and (u == 0 or math.abs(v) < math.abs(u)) then
        -- print(string.format("swap(%d, %d) [%s] [%s]", row, i, e, f))
        s:swap(row, i)
        goto considerSwaps
      end
    end
    if u < 0 then
      s:negate(row)
      -- print(string.format("negate(%d) [%s] [%s]", row, e, s.eqs[row]))
      e = s.eqs[row]
      u = e:at(row)
    end
    local changed = false
    for i = row+1, #s.eqs do
      local f = s.eqs[i]
      local v = f:at(row)
      if v ~= 0 then
        local factor = 1
        if v > 0 then factor = -factor end
        s:add(i, row, factor)
        changed = true
        -- print(string.format("add(%d, %d, %d) [%s] + [%s] = [%s]", i, row, factor, f, e, s.eqs[i]))
      end
    end
    if changed then
      goto considerSwaps
    end
    if not e:empty() and e:single() then
      if e.rhs % e:at(e.first) ~= 0 then
        error(string.format("non-integer single row %d %s", row, e))
      end
      local v = e.rhs / e:at(e.first)
      for i = row-1, 1, -1 do
        local f = s.eqs[i]
        if f:at(e.first) ~= 0 then
          f.rhs = f.rhs - v * f:at(e.first)
          f:set(e.first, 0)
        end
      end
    end
  end
end

local Freevars = {}
local FreevarsMeta = {__index = Freevars}

function Freevars.new()
  return setmetatable({vars = {}, vals = {}}, FreevarsMeta)
end

function Freevars.clone(f)
  local g = Freevars.new()
  for _, v in ipairs(f.vars) do
    g:set(v, f:get(v))
  end
  return g
end

function Freevars.key(f)
  local k = "("
  for _, v in ipairs(f.vars) do
    k = k .. tostring(v) .. "=" .. tostring(f:get(v)) .. ","
  end
  k = k .. ")"
  return k
end

function Freevars.get(f, var)
  return f.vals[var] or 0
end

function Freevars.set(f, var, val)
  if not f.vals[var] then -- otherwise variable already set, just update
    table.insert(f.vars, var)
  end
  f.vals[var] = val
end

function Freevars.total(f)
  local t = 0
  for _, v in ipairs(f.vars) do
    t = t + f:get(v)
  end
  return t
end

function Freevars.applyTo(f, eq)
  for _, v in ipairs(f.vars) do
    local x = eq:at(v)
    if x ~= 0 then
      eq.rhs = eq.rhs - x * f:get(v)
      eq:set(v, 0)
    end
  end
end

function Freevars.successors(f, best, seen, sys)
  local r = {}
  for _, v in ipairs(f.vars) do
    local g = f:clone()
    g:set(v, f:get(v) + 1)
    if g:total() < best then
      local k = g:key()
      if not seen[k] then
        seen[k] = true
        local toobig = false
        for _, e in ipairs(sys.eqs) do
          if e:single() and g.vals[e.first] then
            if e:at(e.first) * g:get(e.first) ~= e.rhs then
              toobig = true
              break
            end
          end
          local hasneg = false
          local sum = 0
          for i = e.first, e.last do
            if e:at(i) < 0 then
              hasneg = true
              break
            end
            if f.vals[i] then
              sum = sum + f.vals[i] * e:at(i)
            end
          end
          if not hasneg and sum > e.rhs then
            toobig = true
            break
          end
        end
        if not toobig then
          table.insert(r, g)
        end
      end
    end
  end
  return r
end

function Freevars.satisfies(f, best, sys)
  local s = sys:clone()
  local g = f:clone()
  local total = g:total()
  for i = #s.eqs, 1, -1 do
    local e = s.eqs[i]
    g:applyTo(e)
    if e:empty() then
      if e.rhs ~= 0 then return false end
    elseif e:single() then
      if e:at(e.first) == 0 then
        error(string.format("zero single in equation %d: %s first=%d last=%d", i, e, e.first, e.last))
      end
      if e.rhs % e:at(e.first) ~= 0 then return false end
      local v = math.tointeger(e.rhs / e:at(e.first))
      if v < 0 then return false end
      g:set(e.first, v)
      total = total + v
      if total >= best then return false end
    else
      return false
    end
  end
  -- print(string.format("solution with %s to\n%s", g:key(), sys))
  return true, total
end

local function solvePart2(machine)
  local eqs = {}
  for i, l in ipairs(machine.levels) do
    local e = Equation.new(l)
    for j, b in ipairs(machine.buttons) do
      if b & (1 << (i-1)) > 0 then
        e:set(j, 1)
      end
    end
    table.insert(eqs, e)
  end
  local sys = EquationSystem.new(eqs)
  local worst = 0
  for i, e in ipairs(sys.eqs) do
    worst = worst + e.rhs
  end
  -- print(string.format("Original system sum %d:", worst))
  -- print(sys)
  sys:reduce()
  -- print("Reduced system:")
  -- print(sys)
  local free = Freevars.new()
  for i = 1, sys.cols do
    if i > #sys.eqs or sys.eqs[i]:at(i) == 0 then
      -- print(string.format("free var %d", i))
      free:set(i, 0)
      for _, e in ipairs(sys.eqs) do
        if e:single() and e.first == i then
          free:set(i, math.tointeger(e.rhs / e:at(i)))
        end
      end
    end
  end
  local seen = {[free:key()] = true}
  local best = worst
  local q = {free}
  repeat
    local f = table.remove(q, 1)
    local ok, total = f:satisfies(best, sys)
    if ok then
      -- print(string.format("solution %d best %d", total, best))
      best = math.min(best, total)
    end
    for _, g in ipairs(f:successors(best, seen, sys)) do
      -- print(string.format("successor size %d", g:total()))
      table.insert(q, g)
    end
  until not next(q) or q[1]:total() >= best
  if best == worst then
    error(string.format("UNLIKELY result best=worst %d", best))
  end
  -- print(string.format("best solution %d", best))
  return best
end

local function part1(lines)
  local input = parseinput(lines)
  local sum = 0
  for i, machine in ipairs(input) do
    -- print(string.format("%d: width %d pattern %d buttons %s levels %s", i, m.width, m.pattern, table.concat(m.buttons, ", "), table.concat(m.levels, ",")))
    sum = sum + countPart1(machine)
  end
  return tostring(sum)
end

local function part2(lines)
  local input = parseinput(lines)
  local sum = 0
  for i, machine in ipairs(input) do
    -- print(string.format("%d: Solving %s", i, lines[i]))
    sum = sum + solvePart2(machine)
  end
  return tostring(sum)
end

Day10 = {part1 = part1, part2 = part2}
setmetatable(Day10, {__tostring = function () return "Day10" end})
if Runner.is_this_main() then
  os.exit(Runner.run(Day10))
end

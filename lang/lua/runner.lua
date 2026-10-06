#!/usr/bin/env lua
-- Copyright 2025 Trevor Stone
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.

-- Advent of Code runner script for Lua.  Solution programs should call
-- require('runner'), then construct a table with part1 and part2 methods and
-- pass that to Runner.run.
Runner = {
  verbose = false,
  signs = {success = "✅", fail = "❌", unknown = "❓", todo = "❗"},
}

--[[
Run a solution on all inputs given to the program.
Expects a table with 'part1' and 'part2' functions as fields.
If -v argument is present, prints status information to stderr.
]]--
function Runner.run(day)
  local files = {}
  for i, a in ipairs(arg) do
    if a == '-v' then
      Runner.verbose = true
    else
      files[#files+1] = a
    end
  end
  if #files == 0 then
    files = {'-'} -- stdin
  end
  local success = true
  for i, f in ipairs(files) do
    success = Runner.runfile(day, f) and success
  end
  return success
end

function Runner.runfile(day, fname)
  local lines = {}
  local f
  if fname == '-' then
    f = io.input()
  else
    f = io.open(fname, 'r')
  end
  if not f then
    error(string.format('could not open file %s', fname))
  end
  for line in f:lines() do
    lines[#lines+1] = line
  end
  if f ~= '-' then
    f:close()
  end
  local expected = {}
  if fname:sub(-4) == '.txt' then
    local found, expectedlines = pcall(io.lines, fname:sub(1, -4) .. 'expected')
    if found then
      for l in expectedlines do
        local part, val = l:match('(part%d):%s*(.*)')
        if part then
          expected[part] = val
        end
      end
    end
  end
  local p1 = Runner.runpart(day, 'part1', lines, expected['part1'], fname)
  local p2 = Runner.runpart(day, 'part2', lines, expected['part2'], fname)
  return not (p1 == 'fail' or p2 == 'fail')
end

local function format_elapsed(seconds)
  if seconds < 0.001 then
    return string.format('%dμs', seconds * 1000000 // 1)
  elseif seconds < 1 then
    return string.format('%dms', seconds * 1000 // 1)
  elseif seconds < 60 then
    return string.format('%.3fs', seconds)
  elseif seconds < 3600 then
    return string.format('%d:%02d', seconds // 60, seconds % 60)
  else
    return string.format('%d:%02d:%02d', seconds // 3600, (seconds % 3600) // 60, seconds % 60)
  end
end

function Runner.runpart(day, part, lines, expected, fname)
  if Runner.verbose then
    io.stderr:write(string.format('Running %s %s on %s: (%d lines)\n', day, part, fname, #lines))
  end
  local starttime = os.time() -- seconds resolution
  local startclock = os.clock() -- CPU time, not wall time
  local result = tostring(day[part](lines))
  local endclock = os.clock()
  local endtime = os.time()
  local difftime = os.difftime(endtime, starttime)
  if difftime < 60 and difftime < (endclock - startclock) then
    difftime = endclock - startclock
  end
  print(string.format('%s: %s', part, result))
  local status = 'unknown'
  if result == expected then
    status = 'success'
  elseif result == 'TODO' then
    status = 'todo'
  elseif expected and expected ~= '' then
    status = 'fail'
  end
  if Runner.verbose then
    local message = ''
    if status == 'success' or status == 'unknown' then
      message = string.format('got %s', result)
    elseif status == 'fail' then
      message = string.format('got %s, wanted %s', result, expected)
    elseif status == 'todo' then
      if not expected or expected == '' then
        message = string.format('implement it')
      else
        message = string.format('implement it, want %s', expected)
      end
    end
    io.stderr:write(string.format('%s %s %s\n', Runner.signs[status], status:upper(), message))
    io.stderr:write(string.format('%s took %s on %s\n', part, format_elapsed(difftime), fname))
    io.stderr:write(string.rep('=', 40) .. '\n')
  end
  return status
end

function Runner.is_this_main()
  local callerfile = debug.getinfo(2).short_src
  return arg[0] == callerfile
end

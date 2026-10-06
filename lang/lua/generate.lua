#!/usr/bin/env lua
-- Copyright 2025 Trevor Stone
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.

-- Creates a skeletal Advent of Code solution in Lua and creates any needed
-- files, links, and directories in support.

if #arg < 1 then
  print(string.format('Usage: %s day1', arg[0]))
  os.exit(false)
end

function exists(fname)
  local f = io.open(fname)
  if f then
    io.close(f)
    return true
  end
  return false
end

function maybewrite(fname, content)
  if not exists(fname) then
    local f = io.open(fname, 'a')
    if not f then
      error('could not create ' .. fname)
    end
    f:write(content)
    io.close(f)
  end
end

function mkdir(dir)
  if not os.execute('mkdir -p ' .. dir) then
    error('could not create directory ' .. dir)
  end
end

LUA_TEMPLATE =
[==[#!/usr/bin/env lua
-- Copyright _COPYDATE_ Trevor Stone
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.

--[[ Advent of Code _YEAR_ day _DAYNUM_
Read the puzzle at https://adventofcode.com/_YEAR_/day/_DAYNUM_
]]--

local function require_relative(script)
  local scriptdir = debug.getinfo(2, "S").source:match('@(.*/)') or ''
  require(string.format('%s/%s', scriptdir, script))
end
require_relative('runner')

local function parseinput(lines)
  return lines
end

local function part1(lines)
  local input = parseinput(lines)
  for i, line in ipairs(input) do
    -- TODO something
  end
  return 'TODO'
end

local function part2(lines)
  local input = parseinput(lines)
  for i, line in ipairs(input) do
    -- TODO something
  end
  return 'TODO'
end

Day_DAYNUM_ = {part1 = part1, part2 = part2}
setmetatable(Day_DAYNUM_, {__tostring = function () return "Day_DAYNUM_" end})
if Runner.is_this_main() then
  os.exit(Runner.run(Day_DAYNUM_))
end
]==]

for i, dir in ipairs(arg) do
  local daynum = dir:match('(%d+)$')
  local curyear = math.floor(os.time() / (60*60*24*365.2425) + 1970)
  local year = dir:match('(%d%d%d%d)/[^/]*$') or os.getenv('PWD'):match('/(%d%d%d%d)$') or curyear
  print('Generating files in ' .. dir)
  mkdir(dir)
  local luafile = string.format('%s/%s.lua', dir, dir:gsub('.*/', ''))
  if exists(luafile) then
    print(luafile .. ' already exists')
  else
    local f = io.open(luafile, 'w')
    if not f then
      error('could not open ' .. luafile)
    end
    local content = LUA_TEMPLATE:gsub('_DAYNUM_', daynum):gsub('_YEAR_', year):gsub('_COPYDATE_', curyear)
    f:write(content)
    f:close()
    os.execute('chmod a+x ' .. luafile)
  end
  local runnerlua = string.format('%s/runner.lua', dir)
  if not exists(runnerlua) then
      os.execute(string.format('ln -s ../../lang/lua/runner.lua %s', runnerlua))
  end
  maybewrite(dir .. '/input.example.txt', '')
  maybewrite(dir .. '/input.example.expected', 'part1: \npart2: \n')
  for j, f in ipairs({'input.actual.txt', 'input.actual.expected'}) do
    if not os.execute(string.format('stat %s/%s > /dev/null 2> /dev/null', dir, f)) then
      mkdir(string.format('%s/../input/%s', dir, daynum))
      local target = string.format('../input/%s/%s', daynum, f)
      os.execute(string.format('ln -s %s %s/%s', target, dir, f))
      local content = ''
      if f == 'input.actual.expected' then
        content = 'part1: \npart2: \n'
      end
      maybewrite(string.format('%s/%s', dir, f), content)
    end
  end
end

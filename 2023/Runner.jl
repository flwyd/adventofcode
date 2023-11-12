# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code runner for Julia.

module Runner
using Printf

function run_part(func, input, expected)
  stats = @timed func(input)
  Result(stats.value, expected, stats.time, stats.bytes)
end

function run_module(mod, filenames; verbose=false)
  name = nameof(mod)
  ok = true
  for fname in filenames
    lines = readlines(fname == "-" ? stdin : fname)
    len = length(lines)
    expect = expectedfor(fname)
    for func in [mod.part1, mod.part2]
      expected = get(expect, string(func), "")
      if verbose
        println(stderr, "Running $name $func on $fname ($len lines)")
      end
      res = run_part(func, lines, expected)
      println("$func: $(res.got)")
      if verbose
        time = format_seconds(res.time_sec)
        bytes = Base.format_bytes(res.allocated_bytes)
        print_message(stderr, res)
        println(stderr, "$func took $time and $bytes on $fname")
        println(stderr, "="^40)
      end
    end
  end
  return ok
end

expectedfile(inputfile) = replace(inputfile, r"(.*)\.txt$" => s"\1.expected")

function expectedfor(inputfile)
  expectfile = expectedfile(inputfile)
  if expectfile != inputfile && isfile(expectfile)
    open(expectfile) do ef
      map(m -> m.captures[1] => replace(m.captures[2], r"\\n" => "\n"),
        map(l -> match(r"(part\d):\s*(.*)", l), readlines(ef)) |>
        filter(!isnothing))
    end |> Dict{String, String}
  else
    Dict{String, String}()
  end
end

function format_seconds(sec)
  if sec >= 60 * 60
    (m, s) = divrem(sec, 60)
    (h, m) = divrem(m, 60)
    @sprintf("%d:%02d:%02f", h, m, s)
  elseif sec >= 60
    (m, s) = divrem(sec, 60)
    @sprintf("%d:%02.3f", m, s)
  elseif sec >= 1
    @sprintf("%.3fs", sec)
  elseif sec >= 0.001
    @sprintf("%.3fms", sec*1_000)
  else
    @sprintf("%.3fµs", sec*1_000_000)
  end
end

struct Result
  got::Any
  want::String
  time_sec::Float64
  allocated_bytes::Int
end

const OUTCOME_SYMBOLS = Dict(:success => "✅",
  :failure => "❌",
  :unknown => "❓",
  :todo => "❗")
const OUTCOME_BG_COLOR = Dict(:success => :light_green,
  :failure => :light_red,
  :unknown => :magenta,
  :todo => :cyan)
function print_message(io, res::Result)
  o = outcome(res)
  sign = OUTCOME_SYMBOLS[o]
  msg = if o == :success
    "got $(res.got)"
  elseif o == :failure
    "got $(res.got), want $(res.want)"
  elseif o == :unknown
    "got $(res.got)"
  elseif o == :todo && res.want == ""
    "implement it"
  elseif o == :todo
    "implement it, want $(res.want)"
  end
  bg = OUTCOME_BG_COLOR[o]
  buf = IOBuffer()
  printstyled(IOContext(buf, :color => true),
    uppercase(string(o)),
    color=bg,
    reverse=true)
  colored = String(take!(buf))
  println(io, "$sign $colored $msg")
end

function outcome(res::Result)
  if res.got == :TODO
    :todo
  elseif isempty(res.want)
    :unknown
  elseif string(res.got) == res.want
    :success
  else
    :failure
  end
end

end

macro run_if_main()
  srcfile = QuoteNode(__source__.file)
  mod = __module__
  :(if abspath(PROGRAM_FILE) == string($srcfile)
    args = ARGS
    verbose = false
    if isempty(ARGS)
      args = ["-"]
    elseif first(ARGS) in ["-v", "--verbose"]
      verbose = true
      args = args[2:end]
    end
    ok = Runner.run_module($mod, args, verbose=verbose)
    exit(ok ? 0 : 1)
  end)
end

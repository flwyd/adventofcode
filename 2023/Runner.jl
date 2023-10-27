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
  Result(stats.value, expected, stats.time)
end

function run_module(mod, filenames; verbose = false)
  name = nameof(mod)
  ok = true
  for fname in filenames
    lines = readlines(fname == "-" ? stdin : fname)
    len = length(lines)
    expectfile = replace(fname, r"(.*)\.txt$" => s"\1.expected")
    expect = Dict(
      if expectfile != fname && isfile(expectfile)
        open(expectfile) do ef
          map(
            filter(
              !isnothing,
              map(l -> match(r"(part\d):\s*(.*)", l), readlines(ef)),
            )
            ) do m
              m.captures[1] => m.captures[2]
            end
          end
      else
        []
      end,
    )
    for func in [mod.part1, mod.part2]
      expected = get(expect, string(func), "")
      if verbose
        println(stderr, "Running $name $func on $fname ($len lines)")
      end
      res = run_part(func, lines, expected)
      println("$func: $(res.got)")
      if verbose
        time = format_seconds(res.time_sec)
        print_message(stderr, res)
        println(stderr, "$func took $time on $fname")
        println(stderr, "="^40)
      end
    end
  end
  return ok
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
    @sprintf("%.3fms", sec * 1_000)
  else
    @sprintf("%.3fµs", sec * 1_000_000)
  end
end

struct Result
  got::Any
  want::String
  time_sec::Float64
end

function print_message(io, res::Result)
  o = outcome(res)
  sign =
    Dict(:success => "✅", :failure => "❌", :unknown => "❓", :todo => "❗")[o]
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
  bg = Dict(
    :success => :light_green,
    :failure => :light_red,
    :unknown => :magenta,
    :todo => :cyan,
  )[o]
  buf = IOBuffer()
  printstyled(IOContext(buf, :color => true), uppercase(string(o)), color = bg, reverse = true)
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
  :(
    if abspath(PROGRAM_FILE) == string($srcfile)
      args = ARGS
      verbose = false
      if isempty(ARGS)
        args = ["-"]
      elseif first(ARGS) in ["-v", "--verbose"]
        verbose = true
        args = args[2:end]
      end
      ok = Runner.run_module($mod, args, verbose = verbose)
      exit(ok ? 0 : 1)
    end
  )
end

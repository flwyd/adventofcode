#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Script to generate a skeletal Advent of Code solution in Julia.

function generate_into(daydir)
  m = match(r"(\d+)$", daydir)
  if isnothing(m)
    println(stderr, "$daydir doesn't end with a day number")
    exit(1)
  end
  daynum = m.captures[1]
  base = mkpath(daydir)
  jlfile = joinpath(base, "Day$daynum.jl")
  if isfile(jlfile)
    println(stderr, "$jlfile already exists, not overwriting")
  else
    code = """
    #!/usr/bin/env julia
    # Copyright 2023 Google LLC
    #
    # Use of this source code is governed by an MIT-style
    # license that can be found in the LICENSE file or at
    # https://opensource.org/licenses/MIT.
    #
    # https://adventofcode.com/2023/day/$daynum

    module Day$daynum

    function part1(lines)
      :TODO
    end

    function part2(lines)
      :TODO
    end

    include("../Runner.jl")
    @run_if_main
    end
    """
    write(jlfile, code)
    chmod(jlfile, 0o755)
  end
  for context in ["example", "actual"]
    touch(joinpath(base, "input.$context.txt"))
    write(joinpath(base, "input.$context.expected"), "part1: \npart2: \n")
  end
end

if isempty(ARGS)
  println(stderr, "Usage: $PROGRAM_FILE dayXX dayYY")
  exit(1)
end
for dir in ARGS
  generate_into(dir)
end

#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Script to generate a skeletal Advent of Code solution in Julia.

using UUIDs

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

    \"""# Advent of Code 2023 day $daynum
    [Read the puzzle](https://adventofcode.com/2023/day/$daynum)
    \"""
    module Day$daynum

    function part1(lines)
      input = parseinput(lines)
      :TODO
    end

    function part2(lines)
      input = parseinput(lines)
      :TODO
    end

    function parseinput(lines)
      map(lines) do line
        line
      end
    end

    include("../Runner.jl")
    @run_if_main
    end
    """
    write(jlfile, code)
    chmod(jlfile, 0o755)
  end

  # NOTE: Pluto uses tabs for indent https://github.com/fonsp/Pluto.jl/issues/586
  notebook = joinpath(base, "notebook.jl")
  if !isfile(notebook)
    header_uuid = UUIDs.uuid4()
    preamble_uuid = UUIDs.uuid4()
    inputstats_uuid = UUIDs.uuid4()
    functions_uuid = UUIDs.uuid4()
    vars_uuid = UUIDs.uuid4()
    resultshead_uuid = UUIDs.uuid4()
    results_uuid = UUIDs.uuid4()
    code = """
    ### A Pluto.jl notebook ###
    # v0.19.32
    #
    # Copyright 2023 Google LLC
    #
    # Use of this source code is governed by an MIT-style
    # license that can be found in the LICENSE file or at
    # https://opensource.org/licenses/MIT.

    using Markdown
    using InteractiveUtils

    # ╔═╡ $header_uuid
    @doc Day$daynum

    # ╔═╡ $preamble_uuid
    begin
      import Pkg
      Pkg.activate()
      try
        @eval using Revise
      catch e
        @warn "Need to install Revise?" exception=(e)
      end
      using Day$daynum
      using Runner
      inputexample = "input.example.txt"
      inputactual = "input.actual.txt"
      run() = Runner.run_module(Day$daynum, Runner.inputfiles(); verbose=true)
      println("Day$daynum ready, just run() or Day$daynum.part1(readlines(inputexample))")
    end

    # ╔═╡ $inputstats_uuid
    Runner.inputstats();

    # ╔═╡ $functions_uuid
    begin
    	function parseinput(lines)
    		Day$daynum.parseinput(lines)
    		#map(lines) do line
    			#parse(Int, line)
    			#if (m = match(r"^(\\S+) (\\S+)\$", line)) !== nothing
    			#  (foo, bar) = m.captures
    			#end
    		#end
    	end
    end;

    # ╔═╡ $vars_uuid
    begin # Useful variables
    	exampleexpected = Runner.expectedfor(inputexample)
    	examplelines = readlines(inputexample)
    	actualexpected = Runner.expectedfor(inputactual)
    	actuallines = readlines(inputactual)
    	inputa = parseinput(actuallines)
    	input = parseinput(examplelines)
    end

    # ╔═╡ $resultshead_uuid
    md"## Results"

    # ╔═╡ $results_uuid
    Runner.run_module(Day$daynum, [
    inputexample,
    inputactual,
    ], verbose=true)

    # ╔═╡ Cell order:
    # ╟─$header_uuid
    # ╟─$preamble_uuid
    # ╠═$inputstats_uuid
    # ╠═$functions_uuid
    # ╠═$vars_uuid
    # ╟─$resultshead_uuid
    # ╠═$results_uuid
    """
    write(notebook, code)
  end

  mkinput(base, "example")
  inputdir = joinpath(@__DIR__, "input", daynum)
  mkpath(inputdir)
  mkinput(inputdir, "actual")
  for name in readdir(inputdir)
    symlink(relpath(joinpath(inputdir, name), base), joinpath(base, name))
  end
end

function mkinput(dir, context)
  txtfile = joinpath(dir, "input.$context.txt")
  expectedfile = joinpath(dir, "input.$context.expected")
  if !isfile(txtfile)
    touch(txtfile)
  end
  if !isfile(expectedfile)
    write(expectedfile, "part1: \npart2: \n")
  end
end

if isempty(ARGS)
  println(stderr, "Usage: $PROGRAM_FILE dayXX dayYY")
  exit(1)
end
for dir in ARGS
  generate_into(dir)
end

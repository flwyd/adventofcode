### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 9d38cf0b-5834-47bc-a06f-96221d88939e
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day2
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day2, Runner.inputfiles(); verbose=true)
  println("Day2 ready, just run() or Day2.part1(readlines(inputexample))")
end

# ╔═╡ 207a620a-74c9-488f-b1ac-cb06c227ead8
@doc Day2

# ╔═╡ 836013ea-cdd1-45b9-bb78-c3186d58c951
Runner.inputstats();

# ╔═╡ c1da7da4-ca56-43a6-b7e0-ee8fa02f3f2b
begin
	struct Game
		id::Int
		sets
	end
	mutable struct Cubeset
  red::Int
  green::Int
  blue::Int
end
function parseinput(lines)
  #Day2.parseinput(lines)
  map(lines) do line
	  (gnum, rest) = split(line, ": ")
	  clusters = split(rest, "; ")
	  sets = map(clusters) do s
		  cubes = split(s, ", ")
		  cs = Cubeset(0, 0, 0)
		  for c in cubes
			  if endswith(c, "red") cs.red = parse(Int, chopsuffix(c, " red")) end
			  if endswith(c, "green") cs.green = parse(Int, chopsuffix(c, " green")) end
			  if endswith(c, "blue") cs.blue = parse(Int, chopsuffix(c, " blue")) end
		  end
		  cs
	  end
		  Game(parse(Int, chopprefix(gnum, "Game ")), sets)
  end
end
end;

# ╔═╡ e31d2568-f501-4bbf-bb25-47061e5e8f21
begin # Useful variables
exampleexpected = Runner.expectedfor(inputexample)
examplelines = readlines(inputexample)
#input = parseinput(examplelines)
	input = parseinput(readlines(inputactual))
end

# ╔═╡ 6ba23178-9c1e-4794-b7e0-8d710525ca59
p1valid = filter(g -> all(cs -> cs.red <= 12 && cs.green <= 13 && cs.blue <= 14, g.sets), input)

# ╔═╡ 2c52d223-2d5f-4068-8ae2-f95a7d56a673
validids = map(g -> g.id, p1valid)

# ╔═╡ 477114b4-8dd2-47a9-a0ef-25be6219db61
sum(validids)

# ╔═╡ d1c0bba9-2b81-47d3-9b50-0d0c3d839e35
md"## Results"

# ╔═╡ 175151b2-3a74-4b9d-9a8a-b59b10e495c4
Runner.run_module(Day2, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─207a620a-74c9-488f-b1ac-cb06c227ead8
# ╟─9d38cf0b-5834-47bc-a06f-96221d88939e
# ╠═836013ea-cdd1-45b9-bb78-c3186d58c951
# ╠═c1da7da4-ca56-43a6-b7e0-ee8fa02f3f2b
# ╠═e31d2568-f501-4bbf-bb25-47061e5e8f21
# ╠═6ba23178-9c1e-4794-b7e0-8d710525ca59
# ╠═2c52d223-2d5f-4068-8ae2-f95a7d56a673
# ╠═477114b4-8dd2-47a9-a0ef-25be6219db61
# ╟─d1c0bba9-2b81-47d3-9b50-0d0c3d839e35
# ╠═175151b2-3a74-4b9d-9a8a-b59b10e495c4

### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 11822fe6-85a6-4562-8482-b46d0d3d275e
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day8
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day8, Runner.inputfiles(); verbose=true)
  println("Day8 ready, just run() or Day8.part1(readlines(inputexample))")
end

# ╔═╡ 8f3d4d33-e7a1-4214-8c90-05274e7b92c0
@doc Day8

# ╔═╡ 619d6099-8ab7-4a04-aab3-c9ad1c1bcf83
Runner.inputstats();

# ╔═╡ ca85d338-80e4-46af-8406-8ffa43ace825
begin
	function parseinput(lines)
		steps = Iterators.cycle([c for c in lines[1]])
		graph = Dict()
		Day8.parseinput(lines)
		map(lines) do line
			#parse(Int, line)
			if (m = match(r"^(\w+) = \((\w+), (\w+)\)$", line)) !== nothing
			  node, left, right = m.captures
			graph[node] = (left, right)
			end
		end
		steps, graph
	end
end;

# ╔═╡ 4a4cf021-e015-4986-bc89-390f17ae658b
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	ex3lines = readlines("input.example3.txt")
	inputa = parseinput(actuallines)
	input = parseinput(inputlines)
	steps, graph = input
end

# ╔═╡ 179a2b69-84b2-4703-96c8-d11cbf50c1cf
begin
	cur = "AAA"
	numsteps = 0
	for dir in steps
		if cur == "ZZZ"
			break
		end
		numsteps += 1
		cur = dir == 'L' ? graph[cur][1] : graph[cur][2]
	end
	numsteps
end

# ╔═╡ 9bffb1bf-a062-48be-bc70-3f88b7b4fa15
begin
	local cur2 = collect(keys(graph) |> filter(endswith("A")))
	numsteps2 = 0
	for dir in steps
		if all(endswith("Z"), cur2)
			break
		end
		numsteps2 += 1
		next = map(cur2) do c
		  dir == 'L' ? graph[c][1] : graph[c][2]
		end
		cur2 = next
	end
	numsteps2
end

# ╔═╡ 0935baa5-c801-4630-bb9b-8dec411ff518
md"## Results"

# ╔═╡ c09ee10e-e764-499d-9ce7-0ab56a70129f
Runner.run_module(Day8, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─8f3d4d33-e7a1-4214-8c90-05274e7b92c0
# ╟─11822fe6-85a6-4562-8482-b46d0d3d275e
# ╠═619d6099-8ab7-4a04-aab3-c9ad1c1bcf83
# ╠═ca85d338-80e4-46af-8406-8ffa43ace825
# ╠═4a4cf021-e015-4986-bc89-390f17ae658b
# ╠═179a2b69-84b2-4703-96c8-d11cbf50c1cf
# ╠═9bffb1bf-a062-48be-bc70-3f88b7b4fa15
# ╟─0935baa5-c801-4630-bb9b-8dec411ff518
# ╠═c09ee10e-e764-499d-9ce7-0ab56a70129f

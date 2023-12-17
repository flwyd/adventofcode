### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 804a2437-bb54-4db8-afbc-f893e3f853e4
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day17
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day17, Runner.inputfiles(); verbose=true)
  println("Day17 ready, just run() or Day17.part1(readlines(inputexample))")
end

# ╔═╡ 201ccf19-5636-4615-a633-1133ec4900eb
@doc Day17

# ╔═╡ 770c1fcc-90f9-41e6-be44-e959cc1eefd8
Runner.inputstats();

# ╔═╡ 9b2bf555-c25d-48c4-8cbf-bf3453041a32
begin
	function parseinput(lines)
		permutedims(reduce(hcat, parse.(Int, split(l, "")) for l in lines), (2, 1))
		#Day17.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ 2f7fe291-1033-4a45-909b-b90e40481153
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ c4922160-0603-43dc-b1f5-ef9780d99ef9
grid = inputa

# ╔═╡ ebfb72da-c710-4d36-a958-f20e1d6ed2cb
begin
const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, 1)
const LEFT_TURN = Dict(UP => LEFT, DOWN => RIGHT, LEFT => DOWN, RIGHT => UP)
const RIGHT_TURN = Dict(UP => RIGHT, DOWN => LEFT, LEFT => UP, RIGHT => DOWN)
end

# ╔═╡ 03f73a07-ff1d-458e-8558-b571dd64d0f9
function moves(grid, pos::CartesianIndex{2}, heading::CartesianIndex{2}, straight::Int)
	left = (pos + LEFT_TURN[heading], LEFT_TURN[heading], 1)
	right = (pos + RIGHT_TURN[heading], RIGHT_TURN[heading], 1)
	forward = (straight < 3 ? pos + heading : CartesianIndex(0, 0), heading, straight+1)
	filter(m -> first(m) ∈ keys(grid), [forward, left, right])
end

# ╔═╡ 4f5ad965-0fb6-412e-881c-77bbd401f569
struct State
	heading::CartesianIndex{2}
	steps::Int
	cost::Int
end

# ╔═╡ 4ee1f3b5-27e4-4100-8e36-b69bf157dd69
target = CartesianIndex(lastindex(grid, 1), lastindex(grid, 2))

# ╔═╡ 181afebb-3b7b-40d9-9567-5f4a87cb3600
# ╠═╡ disabled = true
#=╠═╡
begin
	states = similar(grid, Vector{State})
	for i in eachindex(grid)
		states[i] = []
	end
	start = CartesianIndex(1, 1)
	states[start] = [State(DOWN, 0, 0), State(RIGHT, 0, 0)]
	queue = [start]
	while !isempty(queue)
		cur = pop!(queue)
		for s in states[cur]
			for (pos, head, steps) in moves(grid, cur, s.heading, s.steps)
				cost = s.cost + grid[pos]
				if any(x -> x.heading == head && x.cost <= cost, states[pos])
					continue
				end
				push!(states[pos], State(head, steps, cost))
				push!(queue, pos)
			end
		end
	end
	states[target]
end
  ╠═╡ =#

# ╔═╡ f088be28-38a2-42d5-98df-41bcad35219d
# ╠═╡ disabled = true
#=╠═╡
begin
lowest = 0
q = Dict(1 => [(CartesianIndex(1, 1), dir, 0) for dir in (DOWN, RIGHT)])
seen = Set(q[1])
while true
	while lowest ∉ keys(q) || isempty(q[lowest])
		lowest += 1
	end
	pos, heading, straight = pop!(q[lowest])
	state = (pos, heading, straight)
	push!(seen, state)
	if pos == target
		println("Answer: $lowest")
		break
	end
	cost = lowest + grid[pos]
	if cost ∉ keys(q)
		q[cost] = empty(q[1])
	end
	for m in moves(grid, pos, heading, straight)
		if m ∉ seen
			push!(q[cost], m)
		end
	end
end
end
  ╠═╡ =#

# ╔═╡ 7d93f4b1-c85a-4a3d-9390-08308fae4078
md"## Results"

# ╔═╡ eb8200d6-b86b-49fe-acf3-de43f3bfb220
Runner.run_module(Day17, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─201ccf19-5636-4615-a633-1133ec4900eb
# ╟─804a2437-bb54-4db8-afbc-f893e3f853e4
# ╠═770c1fcc-90f9-41e6-be44-e959cc1eefd8
# ╠═9b2bf555-c25d-48c4-8cbf-bf3453041a32
# ╠═2f7fe291-1033-4a45-909b-b90e40481153
# ╠═c4922160-0603-43dc-b1f5-ef9780d99ef9
# ╠═ebfb72da-c710-4d36-a958-f20e1d6ed2cb
# ╠═03f73a07-ff1d-458e-8558-b571dd64d0f9
# ╠═4f5ad965-0fb6-412e-881c-77bbd401f569
# ╠═4ee1f3b5-27e4-4100-8e36-b69bf157dd69
# ╠═181afebb-3b7b-40d9-9567-5f4a87cb3600
# ╠═f088be28-38a2-42d5-98df-41bcad35219d
# ╟─7d93f4b1-c85a-4a3d-9390-08308fae4078
# ╠═eb8200d6-b86b-49fe-acf3-de43f3bfb220

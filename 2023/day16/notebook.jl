### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 0d54cf6a-c06c-4f52-bad4-35599bb0dd10
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day16
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day16, Runner.inputfiles(); verbose=true)
  println("Day16 ready, just run() or Day16.part1(readlines(inputexample))")
end

# ╔═╡ 5281c1ae-eb28-46ed-aea5-97682c7e4c44
@doc Day16

# ╔═╡ 56637e29-504f-49dd-87a6-5d3ce31c5888
Runner.inputstats();

# ╔═╡ e16041df-1b45-4d9a-bb7f-31593e99cceb
begin
	function parseinput(lines)
		permutedims(reduce(hcat, collect.(lines)), (2, 1))
		#Day16.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ 4344ee37-b12a-417b-aa5d-88ba3fef1b49
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ d31663b7-1ae0-4fb6-a628-9bf251100fa4
grid = inputa

# ╔═╡ 81b50826-e4ae-4c97-8a6b-d7d178e2f32e
energized = zeros(Bool, axes(grid))

# ╔═╡ 9ef1252e-17df-467b-a657-95e71d7c62f8
begin
	const UP = CartesianIndex(-1, 0)
	const DOWN = CartesianIndex(1, 0)
	const LEFT = CartesianIndex(0, -1)
	const RIGHT = CartesianIndex(0, 1)
end

# ╔═╡ afce532a-9e2a-49f5-962c-33ec286c42e3
struct Photon
	position::CartesianIndex{2}
	heading::CartesianIndex{2}
end

# ╔═╡ 7d644706-b97f-402c-aa64-2add8490fe30
MOTIONS = Dict(
	('.', UP) => (UP,),
	('.', DOWN) => (DOWN,),
	('.', LEFT) => (LEFT,),
	('.', RIGHT) => (RIGHT,),
	('/', UP) => (RIGHT,),
	('/', DOWN) => (LEFT,),
	('/', LEFT) => (DOWN,),
	('/', RIGHT) => (UP,),
	('\\', UP) => (LEFT,),
	('\\', DOWN) => (RIGHT,),
	('\\', LEFT) => (UP,),
	('\\', RIGHT) => (DOWN,),
	('-', UP) => (LEFT, RIGHT),
	('-', DOWN) => (LEFT, RIGHT),
	('-', LEFT) => (LEFT,),
	('-', RIGHT) => (RIGHT,),
	('|', UP) => (UP,),
	('|', DOWN) => (DOWN,),
	('|', LEFT) => (UP, DOWN),
	('|', RIGHT) => (UP, DOWN),
)

# ╔═╡ 03f6c429-bff2-4db2-8dcf-16b56b28850d


# ╔═╡ 61241965-e79f-4c36-93ac-8eec84264552
begin
photons = [Photon(CartesianIndex(1, 1), RIGHT)]
seen = Set{Photon}()
while !isempty(photons)
	p = pop!(photons)
	if p ∈ seen || p.position ∉ keys(grid)
		continue  # exited the grid
	end
	push!(seen, p)
	energized[p.position] = true
	for heading in MOTIONS[(grid[p.position], p.heading)]
		push!(photons, Photon(p.position + heading, heading))
	end
end
end

# ╔═╡ 5539ca93-4cde-488f-9914-33a8d03096f4
energized

# ╔═╡ c41fb333-93fb-44c0-8388-90ce951b3eb2
count(energized)

# ╔═╡ f6bacb37-220a-4847-94e7-4ccc66ecb63e
md"## Results"

# ╔═╡ 51d95786-51ae-40d1-bd8c-addaa08ffbc4
Runner.run_module(Day16, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─5281c1ae-eb28-46ed-aea5-97682c7e4c44
# ╟─0d54cf6a-c06c-4f52-bad4-35599bb0dd10
# ╠═56637e29-504f-49dd-87a6-5d3ce31c5888
# ╠═e16041df-1b45-4d9a-bb7f-31593e99cceb
# ╠═4344ee37-b12a-417b-aa5d-88ba3fef1b49
# ╠═d31663b7-1ae0-4fb6-a628-9bf251100fa4
# ╠═81b50826-e4ae-4c97-8a6b-d7d178e2f32e
# ╠═9ef1252e-17df-467b-a657-95e71d7c62f8
# ╠═afce532a-9e2a-49f5-962c-33ec286c42e3
# ╠═7d644706-b97f-402c-aa64-2add8490fe30
# ╠═03f6c429-bff2-4db2-8dcf-16b56b28850d
# ╠═61241965-e79f-4c36-93ac-8eec84264552
# ╠═5539ca93-4cde-488f-9914-33a8d03096f4
# ╠═c41fb333-93fb-44c0-8388-90ce951b3eb2
# ╟─f6bacb37-220a-4847-94e7-4ccc66ecb63e
# ╠═51d95786-51ae-40d1-bd8c-addaa08ffbc4

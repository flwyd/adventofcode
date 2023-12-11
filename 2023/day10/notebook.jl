### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 12b4ecf8-ffbc-470b-b63c-9b519539dc16
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day10
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day10, Runner.inputfiles(); verbose=true)
  println("Day10 ready, just run() or Day10.part1(readlines(inputexample))")
end

# ╔═╡ ad8340d6-3728-4894-baca-f04bef919ad1
@doc Day10

# ╔═╡ b87a3b7c-320e-4dba-be89-ea5c529f2090
Runner.inputstats();

# ╔═╡ 3868f1ef-6707-48dd-9b96-490296c84799
begin
	struct Pipe
		shape::Char
		position::CartesianIndex{2}
		neighbors::Vector{CartesianIndex{2}}
	end
	const NORTH = CartesianIndex(-1, 0)
	const SOUTH = CartesianIndex(+1, 0)
	const EAST = CartesianIndex(0, +1)
	const WEST = CartesianIndex(0, -1)
	const DIRS = Dict(
		'|' => [NORTH, SOUTH],
		'-' => [EAST, WEST],
		'L' => [NORTH, EAST],
		'J' => [NORTH, WEST],
		'L' => [NORTH, EAST],
		'7' => [SOUTH, WEST],
		'F' => [SOUTH, EAST],
		'.' => [],
		'S' => [],
	)
	function parseinput(lines)
		shapes = reduce(hcat, collect(line) for line in lines)
		grid = map(collect(pairs(IndexCartesian(), shapes))) do (i, c)
			Pipe(c, i, [i + x for x in DIRS[c]])
		end
		start = findfirst(p -> p.shape == 'S', grid)
		neighbors = filter(x -> start in grid[start + x].neighbors, [NORTH, SOUTH, EAST, WEST])
		grid[start] = Pipe('S', start, neighbors)
		grid
		#@Day10.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ 6314dd47-0a46-4cdd-8a1e-5e97d4f29b68
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 083b0f15-7b8e-4059-9d68-951d516fec46
start = findfirst(p -> p.shape == 'S', input)

# ╔═╡ cdc57d0e-dccd-45f2-beca-a67d26c33051
seen = Set([start])

# ╔═╡ c80e44e8-c675-480c-8dfd-2da657536aa1
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ fdf23a0e-a4c8-4a0c-9f72-0382e8e050f1
begin
	q = [(start, 0)]
	local furthest = 0
while @show !isempty(q)
	@show i, dist = popfirst!(q)
	furthest = max(dist, furthest)
	push(q, map(x -> (x, dist + 1), filter(!in(seen), input[i].neighbors)...))
end
	furthest
end

# ╔═╡ bacea2ce-eb9e-4479-94f8-3b0aaaee55be
q

# ╔═╡ 74457c1d-cc63-47c9-a9ca-0d00e24f0b43
md"## Results"

# ╔═╡ fb3e7629-80c4-4836-95e5-8a3ad815480d
Runner.run_module(Day10, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─ad8340d6-3728-4894-baca-f04bef919ad1
# ╟─12b4ecf8-ffbc-470b-b63c-9b519539dc16
# ╠═b87a3b7c-320e-4dba-be89-ea5c529f2090
# ╠═3868f1ef-6707-48dd-9b96-490296c84799
# ╠═6314dd47-0a46-4cdd-8a1e-5e97d4f29b68
# ╠═083b0f15-7b8e-4059-9d68-951d516fec46
# ╠═cdc57d0e-dccd-45f2-beca-a67d26c33051
# ╠═c80e44e8-c675-480c-8dfd-2da657536aa1
# ╠═fdf23a0e-a4c8-4a0c-9f72-0382e8e050f1
# ╠═bacea2ce-eb9e-4479-94f8-3b0aaaee55be
# ╟─74457c1d-cc63-47c9-a9ca-0d00e24f0b43
# ╠═fb3e7629-80c4-4836-95e5-8a3ad815480d

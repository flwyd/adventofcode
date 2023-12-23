### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 007af734-414a-409d-ad24-689555b80ae5
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day23
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day23, Runner.inputfiles(); verbose=true)
  println("Day23 ready, just run() or Day23.part1(readlines(inputexample))")
end

# ╔═╡ 8a738023-2c56-40bf-8c8d-302ad06ce450
@doc Day23

# ╔═╡ ac69deb5-5810-4e41-a606-d65282d3f7e8
Runner.inputstats();

# ╔═╡ 38d1744c-dab6-4014-a5ef-12c651d62be8
begin
	function parseinput(lines)
		permutedims(reduce(hcat, collect.(lines)), (2, 1))
		#Day23.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ c32db15d-68ec-4d7c-b2cf-0d810b24524f
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 61c85739-e3ab-469f-836a-84e8ae009677
grid = inputa

# ╔═╡ a8298653-f579-4d0e-a2f6-d18e32ebe669
begin
	const LEFT = CartesianIndex(0, -1)
	const RIGHT = CartesianIndex(0, +1)
	const UP = CartesianIndex(-1, 0)
	const DOWN = CartesianIndex(+1, 0)
	const DIRS = (DOWN, RIGHT, UP, LEFT)
	const DOWNHILL = Dict('v' => DOWN, '>' => RIGHT, '^' => UP, '<' => LEFT)
end

# ╔═╡ e11679ed-474f-4dba-b660-c551e9b06b6d
function longestpath(grid, start, target, visited)
	if start == target
		return 1
	end
	cur = grid[start]
	if cur == '#'
		return 0
	end
	vis = visited ∪ (start,)
	dirs = if haskey(DOWNHILL, cur)
		(DOWNHILL[cur],)
	else
		DIRS
	end
	1 + maximum(d -> longestpath(grid, start + d, target, vis), dirs)
end

# ╔═╡ 40d46766-7e9f-48a1-a57d-7fdb610a14e8
start, target = CartesianIndex(1, 2), CartesianIndex(size(grid, 1), size(grid, 2)-1)

# ╔═╡ 323b146a-6b67-4830-9157-44187161b444
function neighbors(grid, cur)
  filter(x -> checkbounds(Bool, grid, x) && grid[x] != '#', map(d -> cur + d, DIRS))
end


# ╔═╡ a364fae6-b6c6-4e4d-9230-7e7fdbad522b
filter(x -> grid[x] != '#' && length(neighbors(grid, x)) > 2, eachindex(IndexCartesian(), grid))

# ╔═╡ 5f7f9380-dfc6-4fbc-b7dd-8d92e830ec63
# ╠═╡ disabled = true
#=╠═╡
longestpath(grid, start, target, Set(CartesianIndex{2}[]))
  ╠═╡ =#

# ╔═╡ 890a0598-ddff-441b-b333-928352775d1b
md"## Results"

# ╔═╡ 668ee23a-58f0-458e-b125-efac9b870a31
Runner.run_module(Day23, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─8a738023-2c56-40bf-8c8d-302ad06ce450
# ╟─007af734-414a-409d-ad24-689555b80ae5
# ╠═ac69deb5-5810-4e41-a606-d65282d3f7e8
# ╠═38d1744c-dab6-4014-a5ef-12c651d62be8
# ╠═c32db15d-68ec-4d7c-b2cf-0d810b24524f
# ╠═61c85739-e3ab-469f-836a-84e8ae009677
# ╠═a8298653-f579-4d0e-a2f6-d18e32ebe669
# ╠═e11679ed-474f-4dba-b660-c551e9b06b6d
# ╠═40d46766-7e9f-48a1-a57d-7fdb610a14e8
# ╠═323b146a-6b67-4830-9157-44187161b444
# ╠═a364fae6-b6c6-4e4d-9230-7e7fdbad522b
# ╠═5f7f9380-dfc6-4fbc-b7dd-8d92e830ec63
# ╟─890a0598-ddff-441b-b333-928352775d1b
# ╠═668ee23a-58f0-458e-b125-efac9b870a31

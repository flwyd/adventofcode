### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ e0e8e4e8-b2df-4efd-8ae2-74bdbb5a2d61
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day13
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day13, Runner.inputfiles(); verbose=true)
  println("Day13 ready, just run() or Day13.part1(readlines(inputexample))")
end

# ╔═╡ 75e0bf6c-d71c-423c-ab00-03743d65661d
@doc Day13

# ╔═╡ ac4d6aaa-195e-44de-8d40-319ed1197668
Runner.inputstats();

# ╔═╡ 5c60fcbe-88e1-4eb0-9a0e-97b62b5e6699
begin
	function parseinput(lines)
		paragraphs = []
		start = 1
		while true
			blank = findnext(isempty, lines, start)
			paragraph = blank === nothing ? lines[start:end] : lines[start:blank-1]
			push!(paragraphs, reduce(hcat, collect.(paragraph)))
			blank === nothing && break
			start = blank + 1
		end
		paragraphs
		#Day13.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ 56c1e0bb-96ed-4cdf-8e40-7cef7b521467
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ d264508d-c0a1-420d-9d04-81323ae4deb6
input[1][5,1:end] == input[1][6,1:end]

# ╔═╡ 752be8a5-bd9b-4540-87cb-80984653c654
size(input[1])

# ╔═╡ 194ecb39-eaac-48d9-916d-86b3a4f51fdc
begin
function vertical_mirror(grid)
	matched = Int[]
	for i in 1:size(grid, 1)-1
		len = min(i, size(grid, 1)-i)
		if grid[i-len+1:i,1:end] == reverse(grid[i+1:i+len,1:end]; dims=1)
			#if matched !== nothing
			#	error("Multiple vertical mirror points $i and $matched")
			#end
			push!(matched, i)
		end
	end
	matched
end
function horizontal_mirror(grid)
	matched = Int[]
	for i in 1:size(grid, 2)-1
		len = min(i, size(grid, 2)-i)
		if grid[1:end,i-len+1:i] == reverse(grid[1:end,i+1:i+len]; dims=2)
			#if matched !== nothing
			#	error("Multiple horizontal mirror points $i and $matched")
			#end
			push!(matched, i)
		end
	end
	matched
end;

function score(grid)
	v = vertical_mirror(grid)
	h = horizontal_mirror(grid)
	if isempty(v) == isempty(h)
		error("Expected one of vertical or horizontal, not $v $h")
	end
	isempty(v) ? 100*only(h) : only(v)
end
end

# ╔═╡ 85910587-c5ad-44dc-a271-848af6d0bf5e
vertical_mirror(input[1])

# ╔═╡ 5fbeec8f-2d0d-4af4-ba1a-94758e0ced14
horizontal_mirror(input[2])

# ╔═╡ 07f3b0d7-c98e-4ea1-8b10-ad5da09dda41
map(score, inputa) |> sum

# ╔═╡ 51d02f38-106d-4c1d-85d1-835f3e3bce1b
function smudge_score(grid)
	oldv = vertical_mirror(grid)
	oldh = horizontal_mirror(grid)
	for (i, p) in enumerate(grid)
		g = copy(grid)
		g[i] = p == '#' ? '.' : '#'
		v = vertical_mirror(g)
		vdiff = setdiff(v, oldv)
		if !isempty(vdiff)
			return only(vdiff)
		end
		h = horizontal_mirror(g)
		hdiff = setdiff(h, oldh)
		if !isempty(hdiff)
			return 100 * only(hdiff)
		end
	end
end

# ╔═╡ 4c990ff0-bd1b-4967-8b2d-80d12bedb142
map(smudge_score, inputa) |> sum

# ╔═╡ 2bfde3f4-850f-4eb3-8ee6-053cf8643ee8
md"## Results"

# ╔═╡ 3dca7c61-d16a-4e9d-9765-a717a6122419
Runner.run_module(Day13, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─75e0bf6c-d71c-423c-ab00-03743d65661d
# ╟─e0e8e4e8-b2df-4efd-8ae2-74bdbb5a2d61
# ╠═ac4d6aaa-195e-44de-8d40-319ed1197668
# ╠═5c60fcbe-88e1-4eb0-9a0e-97b62b5e6699
# ╠═56c1e0bb-96ed-4cdf-8e40-7cef7b521467
# ╠═d264508d-c0a1-420d-9d04-81323ae4deb6
# ╠═752be8a5-bd9b-4540-87cb-80984653c654
# ╠═194ecb39-eaac-48d9-916d-86b3a4f51fdc
# ╠═85910587-c5ad-44dc-a271-848af6d0bf5e
# ╠═5fbeec8f-2d0d-4af4-ba1a-94758e0ced14
# ╠═07f3b0d7-c98e-4ea1-8b10-ad5da09dda41
# ╠═51d02f38-106d-4c1d-85d1-835f3e3bce1b
# ╠═4c990ff0-bd1b-4967-8b2d-80d12bedb142
# ╟─2bfde3f4-850f-4eb3-8ee6-053cf8643ee8
# ╠═3dca7c61-d16a-4e9d-9765-a717a6122419

### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 735a4bea-3aee-4dab-9d95-6ccf69a05162
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day3
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day3, Runner.inputfiles(); verbose=true)
  println("Day3 ready, just run() or Day3.part1(readlines(inputexample))")
end

# ╔═╡ 2f60701e-150a-414d-b3d7-78cc2a81ce55
@doc Day3

# ╔═╡ 96c46df5-10ad-4bd8-bef0-d5add8040c12
Runner.inputstats();

# ╔═╡ e49f45cf-4b46-4c9c-9816-5bcc5face544
begin
parseinput(lines) = reduce(hcat, collect(line) for line in lines)

function neighborhood(grid, point)
  # See https://julialang.org/blog/2016/02/iteration/ for multi-dimensional iteration
  indices = CartesianIndices(grid)
  ifirst, ilast = first(indices), last(indices)
  one = oneunit(ifirst)
  max(ifirst, point - one):min(ilast, point + one)
end

function digitrun(grid, point)
  col = point[2]
  start = stop = point[1]
  firstrow = firstindex(grid, 1)
  lastrow = lastindex(grid, 1)
  while start >= firstrow
    !isdigit(grid[start, col]) && break
    start -= 1
  end
  while stop <= lastrow
    !isdigit(grid[stop, col]) && break
    stop += 1
  end
  # start is now 1 before first digit and stop is 1 after last digit
  CartesianIndex(start + 1, col):CartesianIndex(stop - 1, col)
end

function numberneighbors(grid, point)
  neighbors = neighborhood(grid, point)
  digitneighbors = [n for n in neighbors if isdigit(grid[n])]
  [digitrun(grid, n) for n in digitneighbors]
end

readnum(grid, range) = parse(Int, join(grid[range], ""))
end;

# ╔═╡ 63914d70-76bc-40b7-9991-e073bfb201c7
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	input = parseinput(examplelines)
end

# ╔═╡ af874c05-4f80-477d-8a07-90c42e743b0b
#grid = [input[i][j] for i in 1:length(input), j in 1:length(input[1])]
grid = reduce(hcat, collect(line) for line in examplelines)

# ╔═╡ f711d9dd-17dd-4031-8452-fc75683bc1d5
numberneighbors(grid, CartesianIndex(4, 2))

# ╔═╡ 476f940d-1713-4db9-8f8d-e5212200220a
neighborhood(grid, CartesianIndex(3, 2))

# ╔═╡ fb4709c4-8149-4948-932d-e0acf7f44fc7
numberneighbors(grid, CartesianIndex(3, 2))

# ╔═╡ 64e2c07a-a035-494f-b782-90d125f6556b
rows, cols = size(grid)

# ╔═╡ a00ed6f2-ab22-428f-b860-5d3abd330f16
num = []

# ╔═╡ b4b7e20d-800b-4787-9105-b8d4f2046327
sawsymbol = false

# ╔═╡ 67fc659e-bb81-4d8e-ac45-eef21909e387
nonadjacent = []

# ╔═╡ cf0248b3-1ddf-4594-a9cd-c2ae9b40638c
notparts = zeros(Bool, size(grid))

# ╔═╡ d4dbaa4b-ad91-4f12-be05-60489c83b2b4
for i = 1:rows, j = 1:cols
	c = grid[i, j]
	if c != '.' && !isdigit(c)
		for row = max(1, i-1):min(rows, i+1), col = max(1, j-1):min(cols, j+1)
			notparts[row, col] = true
		end
	end
end

# ╔═╡ 2a9cb3e7-3722-4116-b107-e2eb7dcfd63e
#for i = 1:rows, j = 1:cols
#	c = grid[i, j]
#	if isdigit(c)
#		if isempty(num)
#			sawsymbol = false
#		end
#		push!(num, c)
#		if notparts[i, j]
#			sawsymbol = true
#		end
#	elseif c == '.' || j == cols
#		if !sawsymbol && !isempty(num)
#			push!(nonadjacent, parse(Int, join(num, "")))
#		end
#		num = []
#	end
#end

# ╔═╡ 3e823423-f6b1-4349-8880-cc189fb2a042
nonadjacent

# ╔═╡ 935d9976-f603-4b19-a399-39541cccf305
function digitspan(grid, row, col)
  if !isdigit(grid[row, col]) error("$row,$col is $(grid[row, col])") end
  @show first = something(findlast(!isdigit, grid[row, 1:col]), 0) + 1
  @show last = something(findfirst(!isdigit, grid[row, col:end]), 0) + col - 2
  first:last
end

# ╔═╡ 3ea4027f-23a5-4291-8079-a451cf04e972
digitspan(grid, 9, 6)

# ╔═╡ 9f7c0196-f97e-4434-bbb2-20ce18a73326
for ix in CartesianIndices(grid)
	println(ix)
end

# ╔═╡ 45178326-e100-4b57-a509-64fc788720ae
md"## Results"

# ╔═╡ cea7a4c9-43d2-4b40-8807-9fa05822a60d
Runner.run_module(Day3, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─2f60701e-150a-414d-b3d7-78cc2a81ce55
# ╟─735a4bea-3aee-4dab-9d95-6ccf69a05162
# ╠═96c46df5-10ad-4bd8-bef0-d5add8040c12
# ╠═e49f45cf-4b46-4c9c-9816-5bcc5face544
# ╠═63914d70-76bc-40b7-9991-e073bfb201c7
# ╠═af874c05-4f80-477d-8a07-90c42e743b0b
# ╠═f711d9dd-17dd-4031-8452-fc75683bc1d5
# ╠═476f940d-1713-4db9-8f8d-e5212200220a
# ╠═fb4709c4-8149-4948-932d-e0acf7f44fc7
# ╠═64e2c07a-a035-494f-b782-90d125f6556b
# ╠═a00ed6f2-ab22-428f-b860-5d3abd330f16
# ╠═b4b7e20d-800b-4787-9105-b8d4f2046327
# ╠═67fc659e-bb81-4d8e-ac45-eef21909e387
# ╠═cf0248b3-1ddf-4594-a9cd-c2ae9b40638c
# ╠═d4dbaa4b-ad91-4f12-be05-60489c83b2b4
# ╠═2a9cb3e7-3722-4116-b107-e2eb7dcfd63e
# ╠═3e823423-f6b1-4349-8880-cc189fb2a042
# ╠═935d9976-f603-4b19-a399-39541cccf305
# ╠═3ea4027f-23a5-4291-8079-a451cf04e972
# ╠═9f7c0196-f97e-4434-bbb2-20ce18a73326
# ╟─45178326-e100-4b57-a509-64fc788720ae
# ╠═cea7a4c9-43d2-4b40-8807-9fa05822a60d

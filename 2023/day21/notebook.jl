### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ cff91452-f8de-4f9c-90e7-d9401e980e85
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day21
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day21, Runner.inputfiles(); verbose=true)
  println("Day21 ready, just run() or Day21.part1(readlines(inputexample))")
end

# ╔═╡ 3be9344d-dc9a-4f0c-a0fd-1e515982af6b
@doc Day21

# ╔═╡ 940cafc1-fa7b-4fa4-b993-f90ba7d907eb
Runner.inputstats();

# ╔═╡ 989fd1c9-1bfa-400b-bad4-1323c78c4931
begin
	function parseinput(lines)
		reduce(hcat, collect.(lines))
		#Day21.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ a71f7e18-2a65-4edd-ae49-9bd74bba31b7
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	#input = parseinput(examplelines)
	input = parseinput(readlines("input.example2.txt"))
end

# ╔═╡ 57181363-c5dd-4613-9a70-2e254f3b52b8
grid = inputa

# ╔═╡ 26820ff2-a54c-4e11-87c2-babf3eeb1966
numrounds = size(grid, 1) < 100 ? 6 : 64

# ╔═╡ 4256811e-9d75-44aa-9778-05075c546b0e
rounds = zeros(Bool, (size(grid)..., numrounds+1))

# ╔═╡ 432ae24b-b1a7-4962-bcfa-93fce2354e69
const NEIGHBORS = (CartesianIndex(0, -1), CartesianIndex(0, +1), CartesianIndex(-1, 0), CartesianIndex(+1, 0))

# ╔═╡ f2094f07-5c9e-4986-a986-3fae97cdebd8
neighbors(grid, i) = filter(n -> checkbounds(Bool, grid, n), map(x -> i+x, NEIGHBORS))

# ╔═╡ 43811435-8702-43f1-b59f-07e60c9e7b4b
neighbors(grid, CartesianIndex(1,1))

# ╔═╡ bb14ae69-299f-4bd2-928b-d096217d7336
any(==('#'), grid[66,:])

# ╔═╡ 55b7a021-2692-4514-a389-9575a280990b
rounds[findfirst(==('S'), grid), 1] = true

# ╔═╡ 35801836-e6c8-487e-bf84-1e24ad7600eb
for round in 1:numrounds
	for i in eachindex(IndexCartesian(), grid)
		if grid[i] != '#'
			for x in neighbors(grid, i)
				if rounds[x,round]
					rounds[i,round+1] = true
				end
			end
		end
	end
end

# ╔═╡ db87b9fe-ffca-45d0-b5bc-0fd380088690
count(rounds[:,:,numrounds+1])

# ╔═╡ c73768b8-68c4-4a10-bf02-413a6b5c7995
function printround(grid, rounds, num)
  for i in axes(rounds, 1)
    println(join(map(j -> rounds[i,j,num] ? 'O' : grid[i,j], axes(rounds, 2))))
  end
end

# ╔═╡ d85786cd-da5d-4752-8a42-28272fe695de
function countdests(grid, numrounds, start, printranges=[])
	rounds = zeros(Bool, (size(grid)..., numrounds+1))
	rounds[start, 1] = true
	for round in 1:numrounds
		for i in eachindex(IndexCartesian(), grid)
			if grid[i] != '#'
				for x in neighbors(grid, i)
					if rounds[x,round]
						rounds[i,round+1] = true
					end
				end
			end
		end
		#println("Round $round")
		#printround(grid, rounds, round+1)
	end
	#printround(grid, rounds, numrounds+1)
	for r in printranges
		c = count(rounds[first(r), last(r), numrounds+1])
		println("$r $c")
	end
	count(rounds[:,:,numrounds+1])
end

# ╔═╡ a72adcb6-c2eb-426f-9033-32ca5be24007
function keysizes(singlegrid)
	@show height = size(singlegrid, 1)
	extra = 2
	grid = repeat(singlegrid, outer=[extra*2+1, extra*2+1])
	@show size(grid)
	start = CartesianIndex(Tuple(x ÷ 2 + 1 for x in size(grid)))
	numrounds = height*extra + height÷2
	rounds = zeros(Bool, (size(grid)..., numrounds+1))
	rounds[start, 1] = true
	for round in 1:numrounds
		for i in eachindex(IndexCartesian(), grid)
			if grid[i] != '#'
				for x in neighbors(grid, i)
					if rounds[x,round]
						rounds[i,round+1] = true
					end
				end
			end
		end
	end
	f(rows, cols) = count(rounds[rows, cols, numrounds+1])
	if true
		return reshape([f(i*height+1:(1+i)*height, j*height+1:(1+j)*height) for i in 0:2*extra for j in 0:2*extra], (5, 5))
	end
	Dict(
	:even => f(height+1:2*height, 2*height+1:3*height),
	:odd => f(2*height+1:3*height, 2*height+1:3*height),
	:top => f(1:height, 2*height+1:3*height),
	:bottom => f(4:height+1:5*height, 2*height+1:3*height),
	:left => f(2*height+1:3*height, 1:height),
	:right => f(2*height+1:3*height, 4:height+1:5*height),
	:topleft => f(1:height, height+1:2*height),
	:topright => f(1:height, 3*height+1:4*height),
	:bottomleft => f(4*height+1:5*height, height+1:2*height),
	:bottomright => f(4*height+1:5*height, 3*height+1:4*height),
		:shouldertl => f(2*height+1:3*height, 1:height),
		:shouldertr => f(2*height+1:3*height, 4*height+1:5*height),
		:shoulderbl => f(3*height+1:4*height, 1:height),
		:shoulderbr => f(3*height+1:4*height, 4*height+1:5*height),
	)
end

# ╔═╡ c7cf2662-9ddb-49a9-ab2a-f92163eaed4f
exkeys = keysizes(input)
# right isn't correct

# ╔═╡ 426ad64b-ae37-410c-91a8-6c7fd2fb4e5a
function keysolve(grid, keymat, rounds)
	cells = (rounds - size(grid, 1)÷2)÷size(grid, 1)
	odd = keymat[3, 3]
	even = keymat[2, 3]
	total = 0
	for c in -cells:cells
		evens = max(cells - abs(c), 0)
		odds = max(cells - abs(c) - 1, 0)
		total += evens * even + odds * odd
		if c < 0
			total += keymat[1, 2] + keymat[1, 4]
			if c == -cells
				total += keymat[1, 3]
			else
				total += keymat[2, 2] + keymat[2, 4]
			end
		elseif c == 0
			total += keymat[3, 1] + keymat[3, 5]
		elseif c > 0
			total += keymat[5, 2] + keymat[5, 4]
			if c == cells
				total += keymat[5, 3]
			else
				total += keymat[4, 2] + keymat[4, 4]
			end
		end
	end
	total
end

# ╔═╡ 16ae1bba-eb92-49ff-aa27-3eb23dc2cabf
keysolve(input, exkeys, 71)

# ╔═╡ eb6751f1-7101-48f8-b5d0-d0670f4c5ec6
function repeatandcount(grid, numrounds)
	height = size(grid, 1)
	extra = max(Int(ceil((numrounds - height÷2)/height)), 0)
	larger = repeat(grid, outer=[extra*2+1, extra*2+1])
	@show size(larger)
	center = CartesianIndex(Tuple(x ÷ 2 + 1 for x in size(larger)))
	printrounds = [(i*height+1:(1+i)*height, j*height+1:(1+j)*height) for i in 0:2*extra for j in 0:2*extra]
	#printrounds = [
	#	(1:height, extra*height+1:(1+extra)*height),
	#	(extra*height+1:(1+extra)*height, 1:height),
	#	(extra*height+1:(1+extra)*height, extra*height+1:(1+extra)*height),
	#	(extra*height+1:(1+extra)*height, 2*extra*height+1:(1+2*extra)*height),
	#	(2*extra*height+1:(1+2*extra)*height, extra*height+1:(1+extra)*height)
	#]
	countdests(larger, numrounds, center, printrounds)
end

# ╔═╡ a3442c39-cc0a-4fba-8b41-7bbdff7eae2c
repeatandcount(input, 50)

# ╔═╡ 36b63860-6074-47b4-8d97-58c846654550
ex2out = Dict(10 => 90, 49 => 1878, 50 => 1940, 100 => 7645, 104 => 8288)

# ╔═╡ f8a59a74-1260-4910-bb53-e8ef6910deba
countdests(input, 49, findfirst(==('S'), input))

# ╔═╡ b1cb0cc0-c929-436d-b950-e44cc37eb619
1878 - 44

# ╔═╡ f37cd05a-55ad-41a4-b4da-719b34caa12e
8288 - 47

# ╔═╡ 42fe57f4-8071-4f1f-bf20-3fcd5dbb0353
larger = repeat(input, outer=[9, 9])

# ╔═╡ c06d5ff3-2c73-4930-9725-94668d1026e5
countdests(larger, 49, CartesianIndex(Tuple(x ÷ 2 + 1 for x in size(larger))))

# ╔═╡ 1f2a8b31-01d9-4b2c-99ed-09f2dc659151
largera = repeat(inputa, outer=[3, 3])

# ╔═╡ 218fed88-71e2-4d66-a299-b59dff47275e
#countdests(largera, 1001, CartesianIndex(131 + 66, 131 + 66))

# ╔═╡ 57a11647-0f1a-43c3-b45b-6b4b17dba215
starta = findfirst(==('S'), inputa)

# ╔═╡ b27c9554-697e-4ef3-9f36-81b2777b1a22
magicnumber = 26501365

# ╔═╡ f4b1d2aa-cb0a-4198-8e04-ae7c97498d57
akeys = keysizes(inputa)

# ╔═╡ 8781ba42-c152-41e7-9a36-9cd7e3b9bbad
keysolve(inputa, akeys, magicnumber)

# ╔═╡ d5a018bc-6dd6-4843-aa83-6ca77a17555b
(magicnumber - 65)÷131

# ╔═╡ 19a1b1e6-2fb8-44fd-aca9-3def5a1e6144
armlength = ((magicnumber - (size(inputa, 1) ÷ 2)) ÷ size(inputa, 1))

# ╔═╡ 8de85b41-1ed3-42c9-85f7-41f4bdda0030
armsquare = (armlength-1)^2

# ╔═╡ fc51204d-8312-4e91-b9f7-71eeefa400c8
odd = countdests(inputa, sum(size(inputa)), starta)

# ╔═╡ d0de47ec-cc8f-4281-9cb6-81685263f8ad
even = countdests(inputa, sum(size(inputa))+1, starta)

# ╔═╡ 5b1a6b02-b40a-4305-8447-f730822dd6a7
armlength^2 * even + armlength^2 * odd + odd

# ╔═╡ af197bd4-93ec-49b8-9690-f3719d14e4d7
armsquare * even + armsquare * odd + armlength*2*even + armlength*2*odd + odd

# ╔═╡ d97f9858-3638-4f81-8e7a-b5da9a78ba15
UInt64(594603538417311)

# ╔═╡ 65cdf94c-a6c2-4734-8bb0-8ec410d2c53e
smallmagic = 500

# ╔═╡ ae04d521-f433-4418-9631-7ef04c19b134
smallodd = countdests(input, sum(size(input)), findfirst(==('S'), input))

# ╔═╡ dcc522e2-0599-42b5-a1e8-91813d925026
smalleven = countdests(input, sum(size(input)) + 1, findfirst(==('S'), input))

# ╔═╡ 8d390e6b-a7ef-4d84-ad23-69f8b65e6836
smallarm = ((smallmagic - (size(input, 1) ÷ 2)) ÷ size(input, 1))

# ╔═╡ 302eeed7-8035-4932-853c-b5270858fb09
smallarmsquare = (smallarm-1)^2

# ╔═╡ 7453dc18-9c01-48de-a88f-943324abe736
smallarmsquare * smalleven + smallarmsquare * smallodd + smallarm*2*smalleven + smallarm*2*smallodd + smallodd

# ╔═╡ e79fe8fb-2078-42c3-87fb-244ba0712066
md"## Results"

# ╔═╡ 4906e314-2306-44e1-9fba-de92327c1708
Runner.run_module(Day21, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─3be9344d-dc9a-4f0c-a0fd-1e515982af6b
# ╟─cff91452-f8de-4f9c-90e7-d9401e980e85
# ╠═940cafc1-fa7b-4fa4-b993-f90ba7d907eb
# ╠═989fd1c9-1bfa-400b-bad4-1323c78c4931
# ╠═a71f7e18-2a65-4edd-ae49-9bd74bba31b7
# ╠═57181363-c5dd-4613-9a70-2e254f3b52b8
# ╠═26820ff2-a54c-4e11-87c2-babf3eeb1966
# ╠═4256811e-9d75-44aa-9778-05075c546b0e
# ╠═432ae24b-b1a7-4962-bcfa-93fce2354e69
# ╠═f2094f07-5c9e-4986-a986-3fae97cdebd8
# ╠═43811435-8702-43f1-b59f-07e60c9e7b4b
# ╠═bb14ae69-299f-4bd2-928b-d096217d7336
# ╠═55b7a021-2692-4514-a389-9575a280990b
# ╠═35801836-e6c8-487e-bf84-1e24ad7600eb
# ╠═db87b9fe-ffca-45d0-b5bc-0fd380088690
# ╠═c73768b8-68c4-4a10-bf02-413a6b5c7995
# ╠═d85786cd-da5d-4752-8a42-28272fe695de
# ╠═a72adcb6-c2eb-426f-9033-32ca5be24007
# ╠═c7cf2662-9ddb-49a9-ab2a-f92163eaed4f
# ╠═426ad64b-ae37-410c-91a8-6c7fd2fb4e5a
# ╠═16ae1bba-eb92-49ff-aa27-3eb23dc2cabf
# ╠═eb6751f1-7101-48f8-b5d0-d0670f4c5ec6
# ╠═a3442c39-cc0a-4fba-8b41-7bbdff7eae2c
# ╠═36b63860-6074-47b4-8d97-58c846654550
# ╠═f8a59a74-1260-4910-bb53-e8ef6910deba
# ╠═b1cb0cc0-c929-436d-b950-e44cc37eb619
# ╠═f37cd05a-55ad-41a4-b4da-719b34caa12e
# ╠═42fe57f4-8071-4f1f-bf20-3fcd5dbb0353
# ╠═c06d5ff3-2c73-4930-9725-94668d1026e5
# ╠═1f2a8b31-01d9-4b2c-99ed-09f2dc659151
# ╠═218fed88-71e2-4d66-a299-b59dff47275e
# ╠═57a11647-0f1a-43c3-b45b-6b4b17dba215
# ╠═b27c9554-697e-4ef3-9f36-81b2777b1a22
# ╠═f4b1d2aa-cb0a-4198-8e04-ae7c97498d57
# ╠═8781ba42-c152-41e7-9a36-9cd7e3b9bbad
# ╠═d5a018bc-6dd6-4843-aa83-6ca77a17555b
# ╠═19a1b1e6-2fb8-44fd-aca9-3def5a1e6144
# ╠═8de85b41-1ed3-42c9-85f7-41f4bdda0030
# ╠═fc51204d-8312-4e91-b9f7-71eeefa400c8
# ╠═d0de47ec-cc8f-4281-9cb6-81685263f8ad
# ╠═5b1a6b02-b40a-4305-8447-f730822dd6a7
# ╠═af197bd4-93ec-49b8-9690-f3719d14e4d7
# ╠═d97f9858-3638-4f81-8e7a-b5da9a78ba15
# ╠═65cdf94c-a6c2-4734-8bb0-8ec410d2c53e
# ╠═ae04d521-f433-4418-9631-7ef04c19b134
# ╠═dcc522e2-0599-42b5-a1e8-91813d925026
# ╠═8d390e6b-a7ef-4d84-ad23-69f8b65e6836
# ╠═302eeed7-8035-4932-853c-b5270858fb09
# ╠═7453dc18-9c01-48de-a88f-943324abe736
# ╟─e79fe8fb-2078-42c3-87fb-244ba0712066
# ╠═4906e314-2306-44e1-9fba-de92327c1708

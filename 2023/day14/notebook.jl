### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 05eda5fd-54d2-4713-a021-168c3cb76181
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day14
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day14, Runner.inputfiles(); verbose=true)
  println("Day14 ready, just run() or Day14.part1(readlines(inputexample))")
end

# ╔═╡ bf4534ca-02cc-46eb-97fd-a088054486e9
@doc Day14

# ╔═╡ e6a363eb-ff3e-4d52-bc06-1ffbf8eb3a48
Runner.inputstats();

# ╔═╡ ae0cf244-225a-45fe-aa1d-d00156b277d5
begin
	function parseinput(lines)
		reduce(hcat, collect.(lines))
		#Day14.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
end;

# ╔═╡ e9061b28-9a01-4e5d-b1d7-750b52ed6dad
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ e752eb4a-7279-490f-907b-a5450d9b5a03
input[1,:]

# ╔═╡ 0bb0b5e2-86b0-4321-b9e9-5a034e3cb2a4
function northweight(grid, row)
	south = size(grid, 2) + 1
	lastrock = 0
	weight = 0
	for (i, c) in enumerate(grid[row,:])
		#@show (i, c, lastrock, weight)
		if c == 'O'
			weight += south - (lastrock + 1)
			lastrock += 1
		elseif c == '#'
			lastrock = i
		end
	end
	weight
end

# ╔═╡ 67883304-a3bf-40c9-a192-e3cae30836e7
map(row -> northweight(input, row), 1:size(input, 1)) |> sum

# ╔═╡ 937d2d4a-3ce0-4c8e-9086-0533053f888e
begin
function cyclerocks(grid)
	lastrock = 0
	north = (1, 1, first(axes(grid)))
	west = (2, 1, last(axes(grid)))
	south = (1, -1, reverse(first(axes(grid))))
	east = (2, -1, reverse(last(axes(grid))))
	newgrid = copy(grid)
	for (dim, sign, indexes) in (north, west, south, east)
		for i in indexes
			lastrock = first(indexes) - sign
			inner = selectdim(newgrid, dim, i)
			iter = sign == 1 ? enumerate(inner) : Iterators.reverse(enumerate(inner))
			for (j, c) in iter
				#@show (j, i, c, lastrock)
				if c == 'O'
					target = lastrock+sign
					coord = dim == 1 ? CartesianIndex(i, target) : CartesianIndex(target, i)
					curcoord = dim == 1 ? CartesianIndex(i, j) : CartesianIndex(j, i)
					if coord != curcoord
					@assert newgrid[coord] == '.' "$coord is $(newgrid[coord]) $dim $sign"
					setindex!(newgrid, 'O', coord)
					setindex!(newgrid, '.', curcoord)
					lastrock = target
					else
						lastrock = j
					end
				elseif c == '#'
					lastrock = j
				end
			end
		end
	end
	newgrid
end
end

# ╔═╡ cff79044-e8c7-4b2a-a94c-b8d723291fc8
input

# ╔═╡ b7c20929-a6eb-4eb2-b04b-6a220cc0e2a6
cyclerocks(cyclerocks(cyclerocks(input)))

# ╔═╡ eb870ba7-7de4-42ea-861c-88da97f1437d

function cycleuntilstable(grid)
  cache = Dict(grid => 0)
  totaliters = 1_000_000_000
  remaining = totaliters
  for i in 1:totaliters
    grid = cyclerocks(grid)
    if grid in keys(cache)
      cyclestart = cache[grid]
      size = i - cyclestart
      left = (totaliters - i)
      @show (cyclestart, size, i, left % size)
      remaining = left % size #totaliters - (i + size * @show(left ÷ size))
      break
    end
    cache[grid] = i
    if i % 1_000 == 0
      println(stderr, "Iteration $i")
    end
  end
  println(stderr, "Finishing with $remaining left")
  for _ in 1:remaining
    grid = cyclerocks(grid)
  end
  grid
end


# ╔═╡ b8fd5dbb-d733-4dab-92aa-ae6b223032ab
finalgrid = cycleuntilstable(input)

# ╔═╡ c523423d-63a3-413e-9c1d-0fcc27f9de9a
#score(grid) = map(row -> northweight(grid, row), 1:size(grid, 1)) |> sum
function score(grid)
	result = 0
	for i in axes(grid, 2)
		result += count(==('O'), grid[:,i]) * (size(grid, 2) + 1 - i)
	end
	result
end

# ╔═╡ 47b5f075-1b35-449a-b1fa-8675ca78d30a
score(finalgrid)

# ╔═╡ bbdcf2d6-4799-42d1-8b58-4e05f51ed4a6
num1 = cyclerocks(input)

# ╔═╡ 7b818513-ffea-466c-8c3f-6e384b8f1b12
num2 = cyclerocks(num1)

# ╔═╡ 6a7027bd-162a-49f2-ade7-6dcd63d13238
num3 = cyclerocks(num2)

# ╔═╡ 6e397a5d-47e3-4209-8cf7-6cf30dea5336
permutedims(num2)

# ╔═╡ 45d7e0c1-1ccf-46af-84e2-94d1487df18a
# ╠═╡ disabled = true
#=╠═╡
begin
	tenth = input
	scores = Int[]
	for i in 1:1_000_000
		tenth = cyclerocks(tenth)
		s = score(tenth)
		push!(scores, s)
		if s < 100
			println("$s for iter $i")
			println(tenth)
		end
	end
	scores
	#tenth
end
  ╠═╡ =#

# ╔═╡ fb57f108-2946-4597-b612-d219d56657a6
#=╠═╡
sort(scores)
  ╠═╡ =#

# ╔═╡ 148328dc-9b28-4244-a096-b0180359aa21
map(row -> northweight(finalgrid, row), 1:size(finalgrid, 1)) |> sum

# ╔═╡ fb0d5b36-03ab-4c8f-a734-59057ae44f7e
md"## Results"

# ╔═╡ 4ccf263d-6eac-4929-b164-5f145750dca3
Runner.run_module(Day14, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─bf4534ca-02cc-46eb-97fd-a088054486e9
# ╟─05eda5fd-54d2-4713-a021-168c3cb76181
# ╠═e6a363eb-ff3e-4d52-bc06-1ffbf8eb3a48
# ╠═ae0cf244-225a-45fe-aa1d-d00156b277d5
# ╠═e9061b28-9a01-4e5d-b1d7-750b52ed6dad
# ╠═e752eb4a-7279-490f-907b-a5450d9b5a03
# ╠═0bb0b5e2-86b0-4321-b9e9-5a034e3cb2a4
# ╠═67883304-a3bf-40c9-a192-e3cae30836e7
# ╠═937d2d4a-3ce0-4c8e-9086-0533053f888e
# ╠═cff79044-e8c7-4b2a-a94c-b8d723291fc8
# ╠═b7c20929-a6eb-4eb2-b04b-6a220cc0e2a6
# ╠═eb870ba7-7de4-42ea-861c-88da97f1437d
# ╠═b8fd5dbb-d733-4dab-92aa-ae6b223032ab
# ╠═c523423d-63a3-413e-9c1d-0fcc27f9de9a
# ╠═47b5f075-1b35-449a-b1fa-8675ca78d30a
# ╠═bbdcf2d6-4799-42d1-8b58-4e05f51ed4a6
# ╠═7b818513-ffea-466c-8c3f-6e384b8f1b12
# ╠═6a7027bd-162a-49f2-ade7-6dcd63d13238
# ╠═6e397a5d-47e3-4209-8cf7-6cf30dea5336
# ╠═45d7e0c1-1ccf-46af-84e2-94d1487df18a
# ╠═fb57f108-2946-4597-b612-d219d56657a6
# ╠═148328dc-9b28-4244-a096-b0180359aa21
# ╟─fb0d5b36-03ab-4c8f-a734-59057ae44f7e
# ╠═4ccf263d-6eac-4929-b164-5f145750dca3

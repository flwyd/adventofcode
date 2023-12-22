### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ b2b80399-6b63-4650-9b1c-f4cabcda8b1d
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day22
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day22, Runner.inputfiles(); verbose=true)
  println("Day22 ready, just run() or Day22.part1(readlines(inputexample))")
end

# ╔═╡ b39b47a5-444e-4ecb-8a0e-f520c1993e63
@doc Day22

# ╔═╡ b651acdc-39a8-4db2-92db-ec4f2f387339
Runner.inputstats();

# ╔═╡ 0591fa95-eada-4f62-b9d3-1eed5f09054d
struct Brick
	first::Tuple{Int,Int,Int}
	second::Tuple{Int,Int,Int}
end

# ╔═╡ 5b9b8e4b-ce66-4452-a14f-29bfac83d6ee
squares(b::Brick, axis::Int) = min(b.first[axis], b.second[axis]):max(b.first[axis], b.second[axis])


# ╔═╡ 4fdc07c2-7db4-43d5-9ce8-2440159a7e07
begin
	function parseinput(lines)
		#Day22.parseinput(lines)
		map(lines) do line
			first, second = split(line, "~")
			b = Brick(Tuple(parse.(Int, split(first, ","))), Tuple(parse.(Int, split(second, ","))))
			if b.first[1] > b.second[1] || b.first[2] > b.second[2] || b.first[3] > b.second[3]
				error(string(line))
			end
			b
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
	end
end;

# ╔═╡ 52e268a0-198b-4aaf-9a3f-a3324a5d93e2
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 9c410a95-bd49-4c59-a0a3-5448566ae9df
#sort(inputa; by=b -> squares(b, 3))

# ╔═╡ 67608b28-f598-4aca-afcd-9eab71098805
movez(b::Brick, bottom::Int) = Brick((b.first[1], b.first[2], bottom), (b.second[1], b.second[2], bottom-1+length(squares(b, 3))))

# ╔═╡ 35327bd4-86f3-484c-833c-f2cffb7c2090
topz(b::Brick) = max(b.first[3], b.second[3])

# ╔═╡ f0f0d6d9-3259-4a5e-860a-0f672b916850
bottomz(b::Brick) = min(b.first[3], b.second[3])

# ╔═╡ 54ce1fa2-a7e1-4b9c-8545-086d861c9bf1
overlapxy(a::Brick, b::Brick) = !isdisjoint(squares(b, 1), squares(a, 1)) && !isdisjoint(squares(b, 2), squares(a, 2))

# ╔═╡ 821ea28d-047f-4166-aeb5-af39647716aa
function fall(bricks::Vector{Brick})
	result = Brick[]
	for brick in sort(bricks; by=b -> squares(b, 3))
		landed = false
		for i in length(result):-1:1
			b = result[i]
			if overlapxy(brick, b)
				newz = movez(brick, topz(b)+1)
				above = findnext(x -> topz(x) > topz(b), result, i+1)
				#@show (newz, b, above, brick)
				#insert!(result, something(above, length(result)+1), newz)
				push!(result, newz)
				landed = true
				break
			end
		end
		if !landed
			newz = movez(brick, 1)
			top = topz(newz)
			below = findlast(b -> topz(b) < top, result)
			above = findfirst(x -> topz(x) > top, result)
			#@show (newz, above, brick)
			#insert!(result, something(below, length(result)) + 1, newz)
			#insert!(result, something(above, length(result)+1), newz)
			push!(result, newz)
		end
		sort!(result, by=topz)
	end
	#sort!(result, by=b -> squares(b, 3))
	result
end

# ╔═╡ 1374c208-3273-4039-821b-bc70c08d1f90
bricks = fall(inputa)

# ╔═╡ 9de6d47a-0315-4874-ac91-0bc9ce94564e
supports = [findall(b -> topz(b) == bottomz(brick)-1 && overlapxy(b, brick), bricks) for brick in bricks]

# ╔═╡ da014d36-3cb7-45ba-87e1-b398340cdfdf
begin
	removable = Int[]
	for i in eachindex(bricks)
		resting = filter(o -> i ∈ o && length(o) == 1, supports)
		#@show (i, collect(resting))
		if isempty(resting)
			push!(removable, i)
		end
	end
end

# ╔═╡ c6abf52b-a2dc-4487-aef7-82e55d57089e
length(removable)

# ╔═╡ 034f65e6-885f-4310-a1eb-02a760ae25b4
#begin
#	chains = zeros(Int, size(bricks))
#	supporting = [Int[] for _ in eachindex(bricks)]
#	for i in reverse(eachindex(bricks))
#		for j in eachindex(supports)
#			if i ∈ supports[j]
#				supporting[i] = vcat(supporting[i], (j,), supporting[j])
#				if length(supports[j]) == 1
#					chains[i] += 
#			end
#		end
#		if num ==
#		chains[i]
#	end
#end

# ╔═╡ 95e25347-2b12-4806-a99d-7618c7b30687
function chainsize(supports, i)
	moving = Set([i])
	chain = 0
	for j in 2:length(supports)
		s = supports[j]
		if !isempty(s) && issubset(s, moving)
			#println("$j supported by $moving")
			chain += 1
			push!(moving, j)
		end
	end
	chain
end

# ╔═╡ da59f986-fefd-41e0-be9a-3c62bf47d7ee
chains = [chainsize(supports, i) for i in eachindex(bricks)]

# ╔═╡ 50eeb81e-80f3-4d7a-acc7-306ff6d12a23
sum(chains)

# ╔═╡ 6a172853-4309-4113-b5a6-d3f028d6bdcb
md"## Results"

# ╔═╡ 9f3dbb52-a48f-46fe-a6fd-8640ed782a9b
Runner.run_module(Day22, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─b39b47a5-444e-4ecb-8a0e-f520c1993e63
# ╟─b2b80399-6b63-4650-9b1c-f4cabcda8b1d
# ╠═b651acdc-39a8-4db2-92db-ec4f2f387339
# ╠═0591fa95-eada-4f62-b9d3-1eed5f09054d
# ╠═5b9b8e4b-ce66-4452-a14f-29bfac83d6ee
# ╠═4fdc07c2-7db4-43d5-9ce8-2440159a7e07
# ╠═52e268a0-198b-4aaf-9a3f-a3324a5d93e2
# ╠═9c410a95-bd49-4c59-a0a3-5448566ae9df
# ╠═67608b28-f598-4aca-afcd-9eab71098805
# ╠═35327bd4-86f3-484c-833c-f2cffb7c2090
# ╠═f0f0d6d9-3259-4a5e-860a-0f672b916850
# ╠═54ce1fa2-a7e1-4b9c-8545-086d861c9bf1
# ╠═821ea28d-047f-4166-aeb5-af39647716aa
# ╠═1374c208-3273-4039-821b-bc70c08d1f90
# ╠═9de6d47a-0315-4874-ac91-0bc9ce94564e
# ╠═da014d36-3cb7-45ba-87e1-b398340cdfdf
# ╠═c6abf52b-a2dc-4487-aef7-82e55d57089e
# ╠═034f65e6-885f-4310-a1eb-02a760ae25b4
# ╠═95e25347-2b12-4806-a99d-7618c7b30687
# ╠═da59f986-fefd-41e0-be9a-3c62bf47d7ee
# ╠═50eeb81e-80f3-4d7a-acc7-306ff6d12a23
# ╟─6a172853-4309-4113-b5a6-d3f028d6bdcb
# ╠═9f3dbb52-a48f-46fe-a6fd-8640ed782a9b

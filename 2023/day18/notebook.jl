### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 5cf31f66-b2be-470b-8836-2015eda90d03
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day18
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day18, Runner.inputfiles(); verbose=true)
  println("Day18 ready, just run() or Day18.part1(readlines(inputexample))")
end

# ╔═╡ 9695a67a-7936-4097-be4a-67035bf435a7
using LinearAlgebra

# ╔═╡ ec919921-52be-415c-abf5-b59eabd2e80c
@doc Day18

# ╔═╡ cf497191-cb84-400a-be98-6aa7130db3b8
Runner.inputstats();

# ╔═╡ fc8d4c41-2d82-4346-a9c3-7cdaaf5763a5
struct Instruction
	direction::CartesianIndex{2}
	distance::Int
	color::AbstractString
end

# ╔═╡ 4d69ff45-8a8d-40aa-8087-91c40caf4731
begin
	const UP = CartesianIndex(-1, 0)
const DOWN = CartesianIndex(1, 0)
const LEFT = CartesianIndex(0, -1)
const RIGHT = CartesianIndex(0, 1)
end

# ╔═╡ fb8b0899-cdb5-4722-ac3e-851cb1c98631
const DIRS = Dict("U" => UP, "D" => DOWN, "L" => LEFT, "R" => RIGHT)

# ╔═╡ 836a2c37-cf18-4d8c-a25f-6ae7390a76e2
begin
	function parseinput(lines)
		#Day18.parseinput(lines)
		map(lines) do line
			#parse(Int, line)
			if (m = match(r"^([RLDU]) (\d+) \(#([a-z0-9]+)\)$", line)) !== nothing
			  (dir, dist, color) = m.captures
				Instruction(DIRS[dir], parse(Int, dist), color)
			else
				error("bad format for $line")
			end
		end
	end
end;

# ╔═╡ 59adfc28-aa64-453f-bdb2-8b8333f302a7
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 66c121a0-454c-4ac0-8f10-a074590f2ecf
instructions = inputa

# ╔═╡ 11d3725b-217c-4c70-a332-dd00fd631c66
extents = Dict(dir => sum(x -> x.distance, filter(x -> x.direction == dir, instructions)) for dir in (UP, DOWN, LEFT, RIGHT))

# ╔═╡ 8a97e7a9-954c-4906-b918-dd5a1b5e2c0f
lava = zeros(Bool, extents[UP] + extents[DOWN] + 1, extents[LEFT] + extents[RIGHT] + 1)

# ╔═╡ 63dc102c-05b8-4bba-a1a5-69a5a4d70990
center = CartesianIndex(extents[UP] + 1, extents[LEFT] + 1)

# ╔═╡ 71bb1786-640c-4464-8e4a-49b7bccd069d
lava[center] = true

# ╔═╡ ff247dd5-503d-4989-99ef-d0b0bc1069d5
cur = center

# ╔═╡ 3c4907f1-bfb6-494c-b4f1-54a0bae950ca
for i in instructions
	for j in 1:i.distance
		cur += i.direction
		lava[cur] = true
	end
end

# ╔═╡ 8bb583b7-fb22-4419-a0bb-4d44f36e67d3
count(lava)

# ╔═╡ 15f9f029-0e63-4814-808f-ae32b5f30a41
exterior = Set{CartesianIndex{2}}()

# ╔═╡ f6dbfb93-8691-4813-9e2c-642b450ed3d1
q = [CartesianIndex(1, 1)]

# ╔═╡ eebefa33-eda1-4a7c-b8c7-78127239b95f
while !isempty(q)
	p = pop!(q)
	if p ∈ exterior
		continue
	end
	push!(exterior, p)
	for dir in (UP, DOWN, LEFT, RIGHT)
		n = p + dir
		if checkbounds(Bool, lava, n) && !lava[n] && n ∉ exterior
			push!(q, n)
		end
	end
end

# ╔═╡ 6d8ecf43-b7e4-4347-8a1f-479453f24b58
exterior

# ╔═╡ 59477d60-89b0-4dce-8f22-c6333333e517
(length(lava), length(exterior), length(lava) - length(exterior))

# ╔═╡ 3aa42110-867e-482b-a0e6-4aa0998fa8bc
const DIR_NUMS = Dict('0' => RIGHT, '1' => DOWN, '2' => LEFT, '3' => UP)

# ╔═╡ 1c7b110f-3845-450d-9610-d016bfacb21d
fromcolor(i::Instruction) = Instruction(DIR_NUMS[last(i.color)], parse(Int, i.color[1:end-1], base = 16), i.color)


# ╔═╡ 9be7d6e3-4d7b-4a01-8c6b-4df00dfc1040
biginstructions = fromcolor.(instructions)

# ╔═╡ 4793361d-ca6f-4587-8628-9c8704bb0717
bigextents = Dict(dir => sum(x -> x.distance, filter(x -> x.direction == dir, biginstructions)) for dir in (UP, DOWN, LEFT, RIGHT))

# ╔═╡ a5deb08a-5b33-4570-8f9c-f5f24be6b808
(bigextents[UP] + bigextents[DOWN] + 1) * (bigextents[LEFT] + bigextents[RIGHT] + 1) / 8 / 1_000_000_000

# ╔═╡ 95449b4e-329d-448c-a935-7d8822028694
bigcur = CartesianIndex(bigextents[UP] + 1, bigextents[LEFT] + 1)

# ╔═╡ f1798652-27c6-4c81-8881-9c4039a65e1e


# ╔═╡ a5717eaf-ae9d-4732-844f-717b4cd9a07c
begin
	(maxrow, maxcol) = (minrow, mincol) = Tuple(bigcur)
for i in biginstructions
	bigcur += i.direction * i.distance
	row, col = Tuple(bigcur)
	minrow = min(minrow, row)
	maxrow = max(maxrow, row)
	mincol = min(mincol, col)
	maxcol = max(maxcol, col)
end
	(minrow, maxrow, mincol, maxcol, maxrow - minrow, maxcol - mincol, (maxrow - minrow) * (maxcol - mincol) / 8 / 1_000_000_000)
end

# ╔═╡ c2447502-3aba-4be0-b3d1-a74259e40feb
bigcur

# ╔═╡ 8cf0067e-ce3e-422a-bba9-119df0544b33
(minrow, maxrow, mincol, maxcol)

# ╔═╡ 12987ebe-46b6-4258-a828-d9bd99ef5c88
begin
pcur = CartesianIndex(0, 0)
edgelength = 0
polygon = [pcur]
for i in biginstructions
	pcur += i.direction * i.distance
	push!(polygon, pcur)
	edgelength += i.distance
end
end

# ╔═╡ 3e496d2c-49b6-4b23-88ff-6d184ec970be
first(polygon), last(polygon)

# ╔═╡ 98bc98ad-6e9e-48d3-84f0-c5a15074451e
edgelength

# ╔═╡ 3efff3ea-0c8f-42e2-ac62-0924416f4bc5
begin
first(polygon) != last(polygon) && error("Can't assume polygon ends on start point")
pairs = zip(Tuple.(polygon[1:end-1]), Tuple.(polygon[2:end]))
shoelaceterms = map(pairs) do (i1, i2)
	d = det([first(i1) first(i2) ; last(i1) last(i2)])
	#d < 1.0 ? 0 : round(Int, d)
end
#@show shoelaces = map((i1, i2) -> [first(i1) first(i2); second(i1) second(i2)], pairs)
#shoelace2sum = det.(shoelaces)
#shoelace2sum / 2
end

# ╔═╡ 86595d17-21f9-4a31-a7c5-ca5df0f6b920
interiorsize = round(Int, abs(sum(shoelaceterms)) / 2)

# ╔═╡ 98f6b101-64a9-4a9b-988e-381ebd4fe7d6
952408144115 - interiorsize - edgelength÷2

# ╔═╡ 9fe6fe15-f481-4bfa-ae17-50b6afb2dae4
interiorsize + edgelength ÷ 2 + 1

# ╔═╡ 5e766fdb-2964-4f52-8b72-11c6b9627bca
md"## Results"

# ╔═╡ d1e7a3fc-c194-4ecb-a7f8-73d72d64e8e9
Runner.run_module(Day18, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─ec919921-52be-415c-abf5-b59eabd2e80c
# ╟─5cf31f66-b2be-470b-8836-2015eda90d03
# ╠═cf497191-cb84-400a-be98-6aa7130db3b8
# ╠═fc8d4c41-2d82-4346-a9c3-7cdaaf5763a5
# ╠═4d69ff45-8a8d-40aa-8087-91c40caf4731
# ╠═fb8b0899-cdb5-4722-ac3e-851cb1c98631
# ╠═836a2c37-cf18-4d8c-a25f-6ae7390a76e2
# ╠═59adfc28-aa64-453f-bdb2-8b8333f302a7
# ╠═66c121a0-454c-4ac0-8f10-a074590f2ecf
# ╠═11d3725b-217c-4c70-a332-dd00fd631c66
# ╠═8a97e7a9-954c-4906-b918-dd5a1b5e2c0f
# ╠═63dc102c-05b8-4bba-a1a5-69a5a4d70990
# ╠═71bb1786-640c-4464-8e4a-49b7bccd069d
# ╠═ff247dd5-503d-4989-99ef-d0b0bc1069d5
# ╠═3c4907f1-bfb6-494c-b4f1-54a0bae950ca
# ╠═8bb583b7-fb22-4419-a0bb-4d44f36e67d3
# ╠═15f9f029-0e63-4814-808f-ae32b5f30a41
# ╠═f6dbfb93-8691-4813-9e2c-642b450ed3d1
# ╠═eebefa33-eda1-4a7c-b8c7-78127239b95f
# ╠═6d8ecf43-b7e4-4347-8a1f-479453f24b58
# ╠═59477d60-89b0-4dce-8f22-c6333333e517
# ╠═3aa42110-867e-482b-a0e6-4aa0998fa8bc
# ╠═1c7b110f-3845-450d-9610-d016bfacb21d
# ╠═9be7d6e3-4d7b-4a01-8c6b-4df00dfc1040
# ╠═4793361d-ca6f-4587-8628-9c8704bb0717
# ╠═a5deb08a-5b33-4570-8f9c-f5f24be6b808
# ╠═95449b4e-329d-448c-a935-7d8822028694
# ╠═f1798652-27c6-4c81-8881-9c4039a65e1e
# ╠═a5717eaf-ae9d-4732-844f-717b4cd9a07c
# ╠═c2447502-3aba-4be0-b3d1-a74259e40feb
# ╠═8cf0067e-ce3e-422a-bba9-119df0544b33
# ╠═9695a67a-7936-4097-be4a-67035bf435a7
# ╠═12987ebe-46b6-4258-a828-d9bd99ef5c88
# ╠═3e496d2c-49b6-4b23-88ff-6d184ec970be
# ╠═98bc98ad-6e9e-48d3-84f0-c5a15074451e
# ╠═3efff3ea-0c8f-42e2-ac62-0924416f4bc5
# ╠═86595d17-21f9-4a31-a7c5-ca5df0f6b920
# ╠═98f6b101-64a9-4a9b-988e-381ebd4fe7d6
# ╠═9fe6fe15-f481-4bfa-ae17-50b6afb2dae4
# ╟─5e766fdb-2964-4f52-8b72-11c6b9627bca
# ╠═d1e7a3fc-c194-4ecb-a7f8-73d72d64e8e9

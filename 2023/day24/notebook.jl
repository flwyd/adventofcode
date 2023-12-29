### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 6c9da82e-2436-4183-a41b-3986625f1fad
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day24
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day24, Runner.inputfiles(); verbose=true)
  println("Day24 ready, just run() or Day24.part1(readlines(inputexample))")
end

# ╔═╡ e16d09c5-d42e-4681-ad46-60a1fca3b712
using LinearAlgebra

# ╔═╡ 1227802c-3d21-4576-a3f2-f0d532e115fe
using Symbolics

# ╔═╡ 771ee2b5-9613-4797-9839-bcea70c04448
@doc Day24

# ╔═╡ fe2ac5a1-54a1-44ec-b14d-8d3961f76bfd
Runner.inputstats();

# ╔═╡ 0be70e79-0df0-4f30-9244-7554a27d5fa4
struct Stone
	init::CartesianIndex{3}
	velocity::CartesianIndex{3}
end

# ╔═╡ eb037dfb-f760-48fd-8b2e-720eba526991
begin
	function parseinput(lines)
		#Day24.parseinput(lines)
		map(lines) do line
			coords, vel = split(line, " @ ")
			x, y, z = parse.(Int, split(coords, ", "))
			dx, dy, dz = parse.(Int, split(vel, ", "))
			Stone(CartesianIndex(x, y, z), CartesianIndex(dx, dy, dz))
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
	end
end;

# ╔═╡ afff40f4-6924-42bf-8b2a-9cef5faa771b
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ f8b22db2-abe0-4abe-b716-32345fb48f53
function coordrange(stones)
	first(stones).init < CartesianIndex(100, 100, 100) ? (7.0, 27.0) : (200000000000000.0, 400000000000000.0)
end

# ╔═╡ 33e68d8a-dded-4a12-bbe1-3ea2cfe34f92
function intersect2d(a::Stone, b::Stone, bounds)
	low, high = bounds
	ax1, ay1, az1 = Tuple(a.init)
	ax2, ay2, az2 = Tuple(a.init + a.velocity)
	bx1, by1, bz1 = Tuple(b.init)
	bx2, by2, bz2 = Tuple(b.init + b.velocity)
	axd = det([ax1 1; ax2 1])
	ayd = det([ay1 1; ay2 1])
	bxd = det([bx1 1; bx2 1])
	byd = det([by1 1; by2 1])
	denom = det([axd ayd; bxd byd])
	if abs(denom) < 0.000001
		@show (a, b, denom)
		#@show "parallel"
		return :parallel
	end
	ad = det([ax1 ay1; ax2 ay2])
	bd = det([bx1 by1; bx2 by2])
	px = det([ad axd; bd bxd]) / denom
	py = det([ad ayd; bd byd]) / denom
	#@show (a, b, px, py)
	if !(low ≤ px ≤ high && low ≤ py ≤ high)
		if abs(px - first(space)) < 1 || abs(px - last(space)) < 1 || abs(py - first(space)) < 1 || abs(py - last(space)) < 1
			@show ("very close", a, b, px, py)
		end
		#@show "outside of space"
		return :outside
	end
	if px < ax1 && ax1 < ax2 || px > ax1 && ax1 > ax2 || px < bx1 && bx1 < bx2 || px > bx1 && bx1 > bx2
		#@show "intersect before"
		return :before
	end
	#@show "intersect"
	return :intersect
end

# ╔═╡ 9bbf6be4-8516-4df9-a8a2-8dddc59e8186
function intersect2dleft(a::Stone, b::Stone, bounds)
	low, high = bounds
	ax1, ay1, az1 = Tuple(a.init)
	ax2, ay2, az2 = Tuple(a.init + a.velocity)
	dax, day, daz = Tuple(a.velocity)
	bx1, by1, bz1 = Tuple(b.init)
	bx2, by2, bz2 = Tuple(b.init + b.velocity)
	dbx, dby, dbz = Tuple(b.velocity)
	aslope = day/dax
	bslope = dby/dbx
	if aslope ≈ bslope
		return :parallel, [-Inf, -Inf]
	end
	aint = ay1 - aslope*ax1
	bint = by1 - bslope*bx1
	res = [-aslope 1; -bslope 1]\[aint, bint]
	if !all(p -> low ≤ p ≤ high, res)
		return :outside, res
	end
	px, py = res
	if sign(dax) * ax1 > sign(dax) * px || sign(dbx) * bx1 > sign(dbx) * px || sign(day) * ay1 > sign(day) * py || sign(dby) * by1 > sign(dby) * py
		return :before, res
	end
	return :intersect, res
end

# ╔═╡ f9f59cc2-f0de-48a9-b473-5aa54baf0b30
[intersect2dleft(inputa[i], inputa[j], coordrange(inputa)) for i in 1:length(inputa)-1 for j in i+1:length(inputa)] 

# ╔═╡ b4bbfbc5-a472-44e1-9833-a350e24a6848
function intersect2dalt(a::Stone, b::Stone, space::AbstractRange{Int})
	ax1, ay1, az1 = Tuple(a.init)
	ax2, ay2, az2 = Tuple(a.init + a.velocity)
	dax, day, daz = Tuple(a.velocity)
	bx1, by1, bz1 = Tuple(b.init)
	bx2, by2, bz2 = Tuple(b.init + b.velocity)
	dbx, dby, dbz = Tuple(b.velocity)

	aslope = day/dax
	bslope = dby/dbx
	if aslope ≈ bslope
		return :parallel
	end
	aint = ay1 - aslope*ax1
	bint = by1 - bslope*bx1
	px = (bint - aint)/(aslope - bslope)
	py = aslope*px + aint
	if !(round(px) ∈ space && round(py) ∈ space)
		if abs(px - first(space)) < 1 || abs(px - last(space)) < 1 || abs(py - first(space)) < 1 || abs(py - last(space)) < 1
			@show ("very close", a, b, px, py)
		end
		#@show "outside of space"
		return :outside
	end
	if px < ax1 && ax1 < ax2 || px > ax1 && ax1 > ax2 || px < bx1 && bx1 < bx2 || px > bx1 && bx1 > bx2
		#@show "intersect before"
		return :before
	end
	#@show "intersect"
	return :intersect
end

# ╔═╡ 1c1da8b4-6359-4333-8ba6-c7fa47a461ab
function matrixform(stones)
	reduce(hcat, map(stones) do s
		x, y, z = Tuple(s.init)
		dx, dy, dz = Tuple(s.init + s.velocity)
		slope = dy/dx
		yint = y - slope * x
		[-slope, 1, yint]
	end)'
end

# ╔═╡ afdaf603-9a7c-4d23-9310-115fa045751d


# ╔═╡ abebc735-5aa3-45af-a870-64bdb32c11ad
matrixform(input[1:2])

# ╔═╡ 3776e93a-1a1a-42aa-92c8-9ce59175ac7b
spaceexample = coordrange(input)

# ╔═╡ 3df25601-c739-4284-8328-3b681686d620
spaceactual = coordrange(inputa)

# ╔═╡ 927d0327-24a2-4d85-897e-6886a3ad4dbc
outcomesex = [map(j -> intersect2dalt(input[i], input[j], spaceexample), i+1:length(input)) for i in 1:length(input)]

# ╔═╡ 9b7a16ef-b920-4f15-8f6a-ef3465d709ea
count(==(:intersect), Iterators.flatten(outcomesex))

# ╔═╡ e4b9bf5e-7c7a-431c-99bc-956ee10da5d6
outcomesa = [map(j -> intersect2dalt(inputa[i], inputa[j], spaceactual), i+1:length(inputa)) for i in 1:length(inputa)]

# ╔═╡ e237849b-256c-4404-bfe7-6a8211d4ee14
count.(==(:intersect), outcomesa)

# ╔═╡ 93662347-9274-444d-ae42-fe87448eebef
count(==(:intersect), Iterators.flatten(outcomesa))

# ╔═╡ 11ef58a6-ef94-403c-bde0-30a7844eb140
count(==(:outside), Iterators.flatten(outcomesa))

# ╔═╡ 345a02b0-1541-4903-82de-52031efdc3f6
count(==(:before), Iterators.flatten(outcomesa))

# ╔═╡ 69bdd4d1-ff01-445b-b851-416c9a28852b
count(==(:parallel), Iterators.flatten(outcomesa))

# ╔═╡ 2f197bdb-903b-478f-a7c7-ff001d4b203f
13906 + 25869 + 5075

# ╔═╡ bc958971-6315-48ac-8875-096d78fafb3b
300*299/2

# ╔═╡ 83e03a7f-2e35-49ca-9e13-59d62eef74b6
function dimrange(s::Stone, dim::Int)
	start = Tuple(s.init)[dim]
	Tuple(s.velocity)[dim] > 0 ? (start:typemax(Int)) : (typemin(Int):start)
end

# ╔═╡ 2feb4028-33fd-41ad-8462-13ec8eae509c
function overlap(stones)
	# doesn't work, need velocity too
	xranges = map(s -> dimrange(s, 1), stones)
	yranges = map(s -> dimrange(s, 2), stones)
	zranges = map(s -> dimrange(s, 3), stones)
	xint = intersect(xranges...)
	yint = intersect(yranges...)
	zint = intersect(zranges...)
	(xint, yint, zint)
end

# ╔═╡ 340d6972-3a8a-4eef-ba7e-c676c9c124b2
overlap(inputa)

# ╔═╡ 56e70ea5-43c2-49f8-802f-7875fdaaa940
heading(s::Stone) = sign.(Tuple(s.velocity))

# ╔═╡ 0494d660-735b-44fc-88e1-468b91a15729
function groupheadings(stones::Vector{Stone})
	byhead = Dict{Tuple{Int, Int, Int}, Vector{Stone}}()
	for s in stones
		signed = heading(s)
		if !haskey(byhead, signed)
			byhead[signed] = Stone[]
		end
		push!(byhead[signed], s)
	end
	byhead
end

# ╔═╡ 441dfd5a-fb52-4a67-87b1-f432d1545c85
byheadex = groupheadings(input)

# ╔═╡ 3d5b11d6-0989-4582-91b1-f6c716c32f10
byheada = groupheadings(inputa)

# ╔═╡ ac491ec7-29d2-4cfc-b712-356cfca750b3
function extreme(head::Tuple{Int, Int, Int}, stones::Vector{Stone})
	res = [0, 0, 0]
	for i in 1:3
		f = head[i] == 1 ? minimum : maximum
		res[i] = f(s -> Tuple(s.init)[i], stones)
	end
	(res[1], res[2], res[3])
end

# ╔═╡ 47e9ed87-56d0-466c-93ff-954f11d0d1e6
[extreme(k, v) for (k, v) in pairs(byheadex)]

# ╔═╡ 5fb14d8e-b9d6-4403-81e7-7c44a39cae55
function symbolize(stones::Vector{Stone})
	@variables ans vx vy vz
	times = Num[]
	eqs = map(enumerate(stones)) do (i, s)
		x, y, z = Tuple(s.init)
		dx, dy, dz = Tuple(s.velocity)
		t = Symbolics.variable(Symbol("t$i"))
		push!(times, t)
		f = x + y + z + (dx + dy + dz)*t
		f ~ ans #+ (vx + vy + vz)*t
	end
	eqs, ans, vx, vy, vz, times
end

# ╔═╡ 3bf54a02-69a1-4ee5-aa7f-00dcbae6e08d
exeqs, ans, vx, vy, vz = symbolize(input)

# ╔═╡ 29eaa015-d9e2-4f3c-811c-dad6693f66fe
exeqs

# ╔═╡ 3237bf5b-85b2-40dd-ab4b-65eead6d941d
Symbolics.solve_for(Symbolics.substitute.(exeqs, (Dict(Symbolics.variable(:t5) => 1),)), [Symbolics.variable(:t1), Symbolics.variable(:t2), Symbolics.variable(:t3), Symbolics.variable(:t4), ans]; check=true)

# ╔═╡ 1784cf3e-9002-439b-9c37-b7b9bf9f3e5d
begin
	bysigns = Dict()
	for s in inputa
		signed = sign.(Tuple(s.velocity))
		if !haskey(bysigns, signed)
			bysigns[signed] = Stone[]
		end
		push!(bysigns[signed], s)
	end
	bysigns
end

# ╔═╡ cca2a4c9-abc7-42ab-b192-0f87f8607fea
corners = [
	sort(bysigns[(1, -1, -1)]; by=s -> Tuple(s.init)[1]),
	sort(bysigns[(-1, 1, -1)]; by=s -> Tuple(s.init)[2]),
	sort(bysigns[(-1, -1, 1)]; by=s -> Tuple(s.init)[3]),
	sort(bysigns[(-1, 1, 1)]; by=s -> -Tuple(s.init)[1]),
	sort(bysigns[(1, -1, 1)]; by=s -> -Tuple(s.init)[2]),
	sort(bysigns[(1, 1, -1)]; by=s -> -Tuple(s.init)[3]),
]

# ╔═╡ f8867370-a8db-4531-8244-d0446af69320
#eqsa, ansa, vxa, vya, vza, timesa = symbolize(corners)

# ╔═╡ db02bc6d-067e-476d-94f6-b7b3f866d763
#t1 = first(timesa)

# ╔═╡ d6c5d436-319d-4592-a474-e13e7d4379de
for corner in corners
	eqsa, ansa, vxa, vya, vza, timesa = symbolize(corner)
for tval in 1:10000
for (i, s) in enumerate(corner)
	if abs(sum(Tuple(s.velocity))) == 3
		continue
	end
	t = timesa[i]
	tosolve = vcat(ans, timesa[1:i-1], timesa[i+1:end])
solvedans, solvedtimes... = Symbolics.solve_for(Symbolics.substitute.(eqsa, (Dict(t => tval),)), tosolve)
	if all(>(0), solvedtimes)
		if !isinteger(solvedans)
			println("Non-integer $t=$tval $solvedans $(round(solvedans))")
		else
			println("$t=$tval $(Int(solvedans))")
		end
		break
	end
#	if !isinteger(solvedans)
#		println("Non-integer solution for $t=$tval $solvedans)")
#	end
end
end
end

# ╔═╡ b8d89bb8-0c13-4f0e-a97e-cf636f510a58
isinteger(solvedans)

# ╔═╡ a59add6c-d0f7-47df-8dd3-3464e4a13a6d
Int(solvedans)

# ╔═╡ 5eda6898-9acd-4fff-b2f2-984cc8a5765e
[Int(t) for t in solvedtimes]

# ╔═╡ d32585fd-f9ec-4dcc-8299-38d11d1cff76


# ╔═╡ 7d73022a-40e0-4133-8150-40fc3ffe4e04
subs = substitute.(exeqs, (Dict(Symbolics.variable(:t1) => 5, Symbolics.variable(:t2) => 3, Symbolics.variable(:t3) => 4, Symbolics.variable(:t4) => 6, Symbolics.variable(:t5) => 1),))

# ╔═╡ 02cc00b6-d951-41c7-9d05-95bfe926c1e5
eqsand = vcat(exeqs, exeqs[1] ~ exeqs[2] ~ exeqs[3] ~ exeqs[4] ~ exeqs[5])

# ╔═╡ d47a8e98-eb64-4be3-acdb-c3cb6de781aa


# ╔═╡ e50090af-3b9a-41c4-851f-622a481df9a7
Symbolics.solve_for(exeqs, [Symbolics.variable(:t1), Symbolics.variable(:t2), Symbolics.variable(:t3), Symbolics.variable(:t4), Symbolics.variable(:t5)])

# ╔═╡ 3b0ad711-8c9b-4d62-95f5-a738e9676255
map(t -> t[2] - t[1], [(minimum(s -> Tuple(s.velocity)[i], inputa), maximum(s -> Tuple(s.velocity)[i], inputa)) for i in 1:3]) |> prod

# ╔═╡ eaa6a15e-c3e1-4f6b-bca5-c2b970f36003
dsubs = Symbolics.substitute(exeqs, (Dict(vx => 1, vy => 1, vz => 1),))

# ╔═╡ b68b5156-22ae-4f80-8472-3e0ebab4e259
Symbolics.solve_for(dsubs, [ans, Symbolics.variable(:t1), Symbolics.variable(:t2), Symbolics.variable(:t3), Symbolics.variable(:t4)])

# ╔═╡ 84d8d362-8319-4665-beb9-c465d53e75f5
Symbolics.solve_for([exeqs[1], exeqs[2]], [ans, Symbolics.variable(:t1)])

# ╔═╡ 7da7c8ab-5288-4a3c-896b-88b2948c0a28
Symbolics.solve_for(exeqs, [ans, vx, vy, vz])

# ╔═╡ b2bc5048-3fdd-4509-aeda-4607432e2780
Symbolics.solve_for(subs, [ans, vx, vy, vz, Symbolics.variable(:t1)])

# ╔═╡ 18815955-ed45-4ed1-95ed-6febf180799d
Symbolics.solve_for(exeqs, [ans, vx, vy, vz])

# ╔═╡ 32e391a7-19bd-440c-a07c-ef2175abda7a
md"## Results"

# ╔═╡ a59f5474-b5b4-4be0-ac19-9c97abd56b93
Runner.run_module(Day24, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─771ee2b5-9613-4797-9839-bcea70c04448
# ╟─6c9da82e-2436-4183-a41b-3986625f1fad
# ╠═fe2ac5a1-54a1-44ec-b14d-8d3961f76bfd
# ╠═e16d09c5-d42e-4681-ad46-60a1fca3b712
# ╠═1227802c-3d21-4576-a3f2-f0d532e115fe
# ╠═0be70e79-0df0-4f30-9244-7554a27d5fa4
# ╠═eb037dfb-f760-48fd-8b2e-720eba526991
# ╠═afff40f4-6924-42bf-8b2a-9cef5faa771b
# ╠═f8b22db2-abe0-4abe-b716-32345fb48f53
# ╠═33e68d8a-dded-4a12-bbe1-3ea2cfe34f92
# ╠═9bbf6be4-8516-4df9-a8a2-8dddc59e8186
# ╠═f9f59cc2-f0de-48a9-b473-5aa54baf0b30
# ╠═b4bbfbc5-a472-44e1-9833-a350e24a6848
# ╠═1c1da8b4-6359-4333-8ba6-c7fa47a461ab
# ╠═afdaf603-9a7c-4d23-9310-115fa045751d
# ╠═abebc735-5aa3-45af-a870-64bdb32c11ad
# ╠═3776e93a-1a1a-42aa-92c8-9ce59175ac7b
# ╠═3df25601-c739-4284-8328-3b681686d620
# ╠═927d0327-24a2-4d85-897e-6886a3ad4dbc
# ╠═9b7a16ef-b920-4f15-8f6a-ef3465d709ea
# ╠═e4b9bf5e-7c7a-431c-99bc-956ee10da5d6
# ╠═e237849b-256c-4404-bfe7-6a8211d4ee14
# ╠═93662347-9274-444d-ae42-fe87448eebef
# ╠═11ef58a6-ef94-403c-bde0-30a7844eb140
# ╠═345a02b0-1541-4903-82de-52031efdc3f6
# ╠═69bdd4d1-ff01-445b-b851-416c9a28852b
# ╠═2f197bdb-903b-478f-a7c7-ff001d4b203f
# ╠═bc958971-6315-48ac-8875-096d78fafb3b
# ╠═83e03a7f-2e35-49ca-9e13-59d62eef74b6
# ╠═2feb4028-33fd-41ad-8462-13ec8eae509c
# ╠═340d6972-3a8a-4eef-ba7e-c676c9c124b2
# ╠═56e70ea5-43c2-49f8-802f-7875fdaaa940
# ╠═0494d660-735b-44fc-88e1-468b91a15729
# ╠═441dfd5a-fb52-4a67-87b1-f432d1545c85
# ╠═3d5b11d6-0989-4582-91b1-f6c716c32f10
# ╠═ac491ec7-29d2-4cfc-b712-356cfca750b3
# ╠═47e9ed87-56d0-466c-93ff-954f11d0d1e6
# ╠═5fb14d8e-b9d6-4403-81e7-7c44a39cae55
# ╠═3bf54a02-69a1-4ee5-aa7f-00dcbae6e08d
# ╠═29eaa015-d9e2-4f3c-811c-dad6693f66fe
# ╠═3237bf5b-85b2-40dd-ab4b-65eead6d941d
# ╠═1784cf3e-9002-439b-9c37-b7b9bf9f3e5d
# ╠═cca2a4c9-abc7-42ab-b192-0f87f8607fea
# ╠═f8867370-a8db-4531-8244-d0446af69320
# ╠═db02bc6d-067e-476d-94f6-b7b3f866d763
# ╠═d6c5d436-319d-4592-a474-e13e7d4379de
# ╠═b8d89bb8-0c13-4f0e-a97e-cf636f510a58
# ╠═a59add6c-d0f7-47df-8dd3-3464e4a13a6d
# ╠═5eda6898-9acd-4fff-b2f2-984cc8a5765e
# ╠═d32585fd-f9ec-4dcc-8299-38d11d1cff76
# ╟─7d73022a-40e0-4133-8150-40fc3ffe4e04
# ╠═02cc00b6-d951-41c7-9d05-95bfe926c1e5
# ╠═d47a8e98-eb64-4be3-acdb-c3cb6de781aa
# ╠═e50090af-3b9a-41c4-851f-622a481df9a7
# ╠═3b0ad711-8c9b-4d62-95f5-a738e9676255
# ╠═eaa6a15e-c3e1-4f6b-bca5-c2b970f36003
# ╠═b68b5156-22ae-4f80-8472-3e0ebab4e259
# ╠═84d8d362-8319-4665-beb9-c465d53e75f5
# ╠═7da7c8ab-5288-4a3c-896b-88b2948c0a28
# ╠═b2bc5048-3fdd-4509-aeda-4607432e2780
# ╠═18815955-ed45-4ed1-95ed-6febf180799d
# ╟─32e391a7-19bd-440c-a07c-ef2175abda7a
# ╠═a59f5474-b5b4-4be0-ac19-9c97abd56b93

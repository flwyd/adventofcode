### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 72039e36-ded0-4f48-9ff3-a31d1189c683
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day5
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day5, Runner.inputfiles(); verbose=true)
  println("Day5 ready, just run() or Day5.part1(readlines(inputexample))")
end

# ╔═╡ a4dcc518-2e86-4767-96e9-917c956a945b
@doc Day5

# ╔═╡ db700e10-3ef8-475d-a098-731b8fb35d1d
Runner.inputstats();

# ╔═╡ 05373b88-94e8-46a0-b4e5-a64e8e1f95d5
begin
struct MapRange
	range::UnitRange{Int}
	dest::Int
end
end

# ╔═╡ 7d98d218-1712-4846-9717-6ee3686b7bc2
begin
	function parseinput(lines)
		seeds = parse.(Int, split(chopprefix(lines[1], "seeds: ")))
		maps = Dict()
		curname = ""
		for line in lines[3:end]
			if endswith(line, " map:")
				cur = MapRange(0:0, 0)
				curname = chopsuffix(line, " map:")
				maps[curname] = []
			elseif !isempty(line)
				(dest, source, len) = parse.(Int, split(line))
				push!(maps[curname], MapRange(source:source+len-1, dest))
			end
		end
		for m in values(maps)
			sort!(m)
		end
		(seeds, maps)
		#Day5.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end

	function indirect(maps, from, to, value)
		matches = maps["$from-to-$to"] |> filter(r -> value in r.range)
		if isempty(matches)
			value
		else
		  m = only(matches)
			value-first(m.range)+m.dest
		end
	end

	function ind(maps, from, to)
		function(value)
			indirect(maps, from, to, value)
		end
	end

	function backwards(maps, from, to, value)
		for mr in maps["$from-to-$to"]
			if 0 <= value - mr.dest < length(mr.range)
				return value - mr.dest + first(mr.range)
			end
		end
		value
	end

	function back(maps, from, to)
		function (value)
			backwards(maps, (from), (to), (value))
		end
	end

	Base.isless(x::MapRange, y::MapRange) = x.range < y.range
end;

# ╔═╡ f787769c-3d6a-4f17-8d62-368a6b04866d
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
	(seeds, maps) = inputa
end

# ╔═╡ 34abaae1-cb0d-4829-8cc3-0455e373c15a
indirect(input[2], "seed", "soil", 97)

# ╔═╡ 623846c7-2525-4e9e-8e51-b537481e18fd
minimum([indirect(maps, "seed", "soil", x) |> ind(maps, "soil", "fertilizer") |> ind(maps, "fertilizer", "water") |> ind(maps, "water", "light") |> ind(maps, "light", "temperature") |> ind(maps, "temperature", "humidity") |> ind(maps, "humidity", "location") for x in seeds])

# ╔═╡ 1246759c-244f-462a-89c7-c14616a91030
sort(maps["humidity-to-location"])

# ╔═╡ 72866944-d1f6-44ce-b89d-de765b1aa940
begin
	struct MetaRange
		dest::Int
		source::Int
		length::Int
	end
end

# ╔═╡ 51ac95bc-c216-4b41-aa02-56fe44427d9e
begin
	function xsplitranges(from, to)
		result = []
		for fmr in from
			for tmr in to
				#@show (fmr, tmr)
				#dr = fmr.dest:fmr.dest+length(fmr.range)-1
				#overlap = dr ∩ tmr.range
				overlap = fmr.range ∩ tmr.range
				if !isempty(overlap)
					push!(result, MapRange(overlap, fmr.dest+(first(overlap) -first(fmr.range))))
				end
			end
		end
		sort(result)
	end

	function splitranges(from, to)
		result = []
		for fmr in from
			for tmr in to
				#@show (fmr, tmr)
				dr = fmr.dest:fmr.dest+length(fmr.range)-1
				overlap = dr ∩ tmr.range
				#overlap = fmr.range ∩ tmr.range
				if !isempty(overlap)
					push!(result, MapRange(overlap, tmr.dest+(first(overlap) -first(tmr.range))))
				end
			end
		end
		sort(result)
	end

	function infill(mapranges)
		highest_possible = 4068806743 + 109269701
		result = []
		nextstart = 0
		for mr in mapranges
			if nextstart < first(mr.range)
			push!(result, MapRange(nextstart:first(mr.range)-1, nextstart))
			end
			nextstart = last(mr.range)+1
			push!(result, mr)
		end
		push!(result, MapRange(nextstart:highest_possible, nextstart))
	end
end;

# ╔═╡ 2577cd18-ce34-452b-b5ef-9f79a6fc8e4b
seedranges = sort(map(x -> x[1]:x[1]+x[2]-1, Iterators.partition(seeds, 2)))

# ╔═╡ 90f65318-78a1-412b-85da-32f316ac3d99
maps["soil-to-fertilizer"]

# ╔═╡ c842d9c7-6d73-4f28-b23c-024ebf84ff63
splitranges(infill(maps["seed-to-soil"]), infill(maps["soil-to-fertilizer"]))

# ╔═╡ 9baf3bf3-0065-4e0b-9fd7-45143f969326
infill(maps["seed-to-soil"])

# ╔═╡ 5df5893d-3383-4421-bd87-61da5114ee57
begin
newnewmaps = Dict()
	newnewmaps["seed-to-soil"] = infill(maps["seed-to-soil"])
	
	newnewmaps["soil-to-fertilizer"] = splitranges(newnewmaps["seed-to-soil"], infill(maps["soil-to-fertilizer"]))
		
	newnewmaps["fertilizer-to-water"] = splitranges(newnewmaps["soil-to-fertilizer"], infill(maps["fertilizer-to-water"]))
	
	newnewmaps["water-to-light"] = splitranges(newnewmaps["fertilizer-to-water"], infill(maps["water-to-light"]))
	
	newnewmaps["light-to-temperature"] = splitranges(newnewmaps["water-to-light"], infill(maps["light-to-temperature"]))
	
	newnewmaps["temperature-to-humidity"] = splitranges(newnewmaps["light-to-temperature"], infill(maps["temperature-to-humidity"]))
	
	newnewmaps["humidity-to-location"] = splitranges(newnewmaps["temperature-to-humidity"], infill(maps["humidity-to-location"]))
end

# ╔═╡ 0bd4c67e-cb5e-4b9b-ad5b-b577f0c91c8f
newnewmaps["humidity-to-location"]

# ╔═╡ 094e9282-164a-453f-9df6-1f9a3a58c6d0
begin
	newmaps = Dict()
	newmaps["humidity-to-location"] = infill(maps["humidity-to-location"])
	newmaps["temperature-to-humidity"] = xsplitranges(infill(maps["temperature-to-humidity"]), newmaps["humidity-to-location"])
	newmaps["light-to-temperature"] = xsplitranges(infill(maps["light-to-temperature"]), newmaps["temperature-to-humidity"])
	newmaps["water-to-light"] = xsplitranges(infill(maps["water-to-light"]), newmaps["light-to-temperature"])
	newmaps["fertilizer-to-water"] = xsplitranges(infill(maps["fertilizer-to-water"]), newmaps["water-to-light"])
	newmaps["soil-to-fertilizer"] = xsplitranges(infill(maps["soil-to-fertilizer"]), newmaps["fertilizer-to-water"])
	newmaps["seed-to-soil"] = xsplitranges(infill(maps["seed-to-soil"]), newmaps["soil-to-fertilizer"])
end

# ╔═╡ 343a805a-3e0a-4138-a7ae-6352fac64e7a
newmaps["temperature-to-humidity"]

# ╔═╡ bb79a46b-1c93-4fac-984e-1d18428e994f
indirect(newmaps, "temperature", "humidity", 93) |> ind(newmaps, "humidity", "location")

# ╔═╡ 953fb3c1-40bb-4d69-981a-d7d68654ac9c
newmaps["seed-to-soil"]

# ╔═╡ 06999de3-3271-4c07-a5eb-834a036d9f35
seedmrs = splitranges(map(r -> MapRange(r, first(r)), sort(seedranges)), newmaps["seed-to-soil"])

# ╔═╡ 40da9847-795e-4c4e-a91e-8284abe28cd6
[(x, indirect(newmaps, "seed", "soil", x) |> ind(newmaps, "soil", "fertilizer") |> ind(newmaps, "fertilizer", "water") |> ind(newmaps, "water", "light") |> ind(newmaps, "light", "temperature") |> ind(newmaps, "temperature", "humidity") |> ind(newmaps, "humidity", "location")
) for x in map(y -> first(y.range), seedmrs)]

# ╔═╡ 93c8ec7a-1414-4d52-9b33-2e5f2ae07796


# ╔═╡ 35e0fcb0-5a8e-45be-9ea2-5981e6e5dd80
seedsbylocation = [(x, backwards(newnewmaps, "humidity", "location", x) |> back(newnewmaps, "temperature", "humidity") |> back(newnewmaps, "light", "temperature") |> back(newnewmaps, "water", "light") |> back(newnewmaps, "fertilizer", "water") |> back(newnewmaps, "soil", "fertilizer") |> back(newnewmaps, "seed", "soil")) for x in map(y -> first(y.dest), newnewmaps["humidity-to-location"])]

# ╔═╡ 3ac1f9f2-8249-45e8-ac6e-5114d7f738df
matches = seedsbylocation |> filter(x -> any(y -> x[2] in y, seedranges))

# ╔═╡ f81bc3ed-bbf4-4861-8aa2-22d7920c75d6
#rangevals = [[indirect(maps, "seed", "soil", x) |> ind(maps, "soil", "fertilizer") |> ind(maps, "fertilizer", "water") |> ind(maps, "water", "light") |> ind(maps, "light", "temperature") |> ind(maps, "temperature", "humidity") |> ind(maps, "humidity", "location") for x in r] for r in seedranges]

# ╔═╡ 0eee52bf-eb23-4890-a485-f58389edcd04
minimum(map(first, matches))

# ╔═╡ 3f4b64da-cda5-4d70-a443-28ac9778268d
md"## Results"

# ╔═╡ 45b9e8e6-8793-4bf5-afa8-b8cf8c79c667
Runner.run_module(Day5, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─a4dcc518-2e86-4767-96e9-917c956a945b
# ╟─72039e36-ded0-4f48-9ff3-a31d1189c683
# ╠═db700e10-3ef8-475d-a098-731b8fb35d1d
# ╠═05373b88-94e8-46a0-b4e5-a64e8e1f95d5
# ╠═7d98d218-1712-4846-9717-6ee3686b7bc2
# ╠═f787769c-3d6a-4f17-8d62-368a6b04866d
# ╠═34abaae1-cb0d-4829-8cc3-0455e373c15a
# ╠═623846c7-2525-4e9e-8e51-b537481e18fd
# ╠═1246759c-244f-462a-89c7-c14616a91030
# ╠═72866944-d1f6-44ce-b89d-de765b1aa940
# ╠═51ac95bc-c216-4b41-aa02-56fe44427d9e
# ╠═2577cd18-ce34-452b-b5ef-9f79a6fc8e4b
# ╠═90f65318-78a1-412b-85da-32f316ac3d99
# ╠═c842d9c7-6d73-4f28-b23c-024ebf84ff63
# ╠═9baf3bf3-0065-4e0b-9fd7-45143f969326
# ╠═343a805a-3e0a-4138-a7ae-6352fac64e7a
# ╠═bb79a46b-1c93-4fac-984e-1d18428e994f
# ╠═5df5893d-3383-4421-bd87-61da5114ee57
# ╠═0bd4c67e-cb5e-4b9b-ad5b-b577f0c91c8f
# ╠═094e9282-164a-453f-9df6-1f9a3a58c6d0
# ╠═953fb3c1-40bb-4d69-981a-d7d68654ac9c
# ╠═06999de3-3271-4c07-a5eb-834a036d9f35
# ╠═40da9847-795e-4c4e-a91e-8284abe28cd6
# ╠═93c8ec7a-1414-4d52-9b33-2e5f2ae07796
# ╠═35e0fcb0-5a8e-45be-9ea2-5981e6e5dd80
# ╠═3ac1f9f2-8249-45e8-ac6e-5114d7f738df
# ╠═f81bc3ed-bbf4-4861-8aa2-22d7920c75d6
# ╠═0eee52bf-eb23-4890-a485-f58389edcd04
# ╟─3f4b64da-cda5-4d70-a443-28ac9778268d
# ╠═45b9e8e6-8793-4bf5-afa8-b8cf8c79c667

### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ dadf8165-fbcf-4d42-b097-bf306d6cbaa7
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day25
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day25, Runner.inputfiles(); verbose=true)
  println("Day25 ready, just run() or Day25.part1(readlines(inputexample))")
end

# ╔═╡ f05c84ea-4374-4925-9e86-d629c1bf5c07
@doc Day25

# ╔═╡ 0fc73caf-1540-49f7-9f62-7fa9e7592048
Runner.inputstats();

# ╔═╡ a754d8d8-3c39-459c-9af1-d45335ec0971
begin
	function parseinput(lines)
		graph = Dict{String, Vector{String}}()
		#Day25.parseinput(lines)
		map(lines) do line
			key, vals = split(line, ": ")
			if !haskey(graph, key)
				graph[key] = String[]
			end
			for v in split(vals, " ")
				push!(graph[key], v)
				if !haskey(graph, v)
					graph[v] = String[]
				end
				push!(graph[v], key)
			end
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
		graph
	end
end;

# ╔═╡ c3e534c0-bd4d-44aa-bc36-8a8ded5dfb0d
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 63ad9391-f0bd-48c1-9493-ff6a2f013f19
begin
	start = last(collect(keys(input)))
	levels = [String[]]
	seen = Set([start])
	q = [(start, 1)]
	while !isempty(q)
		(node, level) = popfirst!(q)
		if length(levels) < level
			push!(levels, String[])
		end
		push!(levels[level], node)
		for n in input[node]
			if n ∉ seen
				push!(q, (n, level+1))
				push!(seen, n)
			end
		end
	end
	levels
end

# ╔═╡ 10dffc73-567e-4806-82a2-dd1c8ddc20c0
function removable(graph, key)
	good = String[] #Dict{String, Int}()
	for a in graph[key]
		#good[a] = 0
		seen = 0
		#maybe = true
		for b in graph[a]
			if a == b
				continue
			end
			if key ∈ graph[b]
				seen += 1
				#good[a] += 1
				#maybe = false
				#break
			end
		end
		if seen == 0
			push!(good, a)
		end
#		if maybe
#			push!(good, maybe)
#		end
	end
	good
end

# ╔═╡ 811d574b-c04e-4b8f-9b27-9a1deca733c9
filter(t -> length(t[2]) != length(t[3]), [(x, removable(inputa, x), inputa[x]) for x in keys(inputa)])

# ╔═╡ 2f14a405-15a6-4559-ab67-896910e68ee9
function ispartitioned(graph, without)
	start = first(keys(graph))
	seen = Set([start])
	q = [start]
	while !isempty(q)
		n = popfirst!(q)
		for v in graph[n]
			if (n, v) ∈ without || (v, n) ∈ without
				continue
			end
			if v ∉ seen
				push!(seen, v)
				push!(q, v)
			end
		end
	end
#	length(seen) != length(graph)
	  if length(seen) != length(graph)
    @show (length(seen), length(graph) - length(seen), length(seen) * (length(graph) - length(seen)))
    return true
  end
  return false
end

# ╔═╡ cbb02737-2804-43de-915b-b1ad74d3625e
ispartitioned(input, [("hfx", "pzl"), ("bvb", "cmg"), ("nvd", "jqt")])

# ╔═╡ 63ebfacb-4771-4042-9216-de294955b0fd
(sum(length.(values(inputa)))/2)^3

# ╔═╡ aceedf67-e921-43c8-9b66-56e6e88a0798
begin
	for k in keys(inputa)
		#if k ∈ ("kgs", "csz", "dvf", "krd")
		#	continue
		#end
		#good = removable(inputa, k)
		#if length(good) != length(inputa[k])
			for v in inputa[k]
			if ispartitioned(inputa, [("kgs", "csz"), ("dvf", "krd"), (k, v)])
				println("$k $v")
			end
			end
		#end
	end
end

# ╔═╡ 172156f9-8561-4df0-b890-d0854cb08a68
alledges = unique(sort(map(Tuple, (Iterators.flatten(map(k -> [sort([k, w]) for w in input[k]], collect(keys(input))))))))

# ╔═╡ f1ed9421-9ec8-47b4-8ecc-050221efef11
alledgesa = unique(sort(map(Tuple, (Iterators.flatten(map(k -> [sort([k, w]) for w in inputa[k]], collect(keys(inputa))))))))

# ╔═╡ 39a16c5b-9a4d-422b-bb66-3825a4c15244
#winners = filter(e -> !isempty(e ∩ ("bdj", "bnv", "ztc")), alledgesa)
winners = (("bdj", "vfh"), ("bnv", "rpd"), ("ttv", "ztc"))

# ╔═╡ e5e3c2b1-7133-4472-8d87-2e3b5a91c480


# ╔═╡ 8bdc86b9-fb4e-43c3-8ed6-9d5ea2984110
for i in 1:length(alledges)
for j in i+1:length(alledges)
for k in j+1:length(alledges)
	a, b, c = alledges[i], alledges[j], alledges[k]
	if ispartitioned(input, (a, b, c))
		println("Partitioned: $a, $b, $c")
	end
end
end
end

# ╔═╡ 1203330b-580e-4642-b665-9d3b2af0c766
# ╠═╡ disabled = true
#=╠═╡
for i in 1:length(alledgesa)
for j in i+1:length(alledgesa)
for k in j+1:length(alledgesa)
	a, b, c = alledgesa[i], alledgesa[j], alledgesa[k]
	if ispartitioned(inputa, (a, b, c))
		println("Partitioned: $a, $b, $c")
	end
end
end
end
  ╠═╡ =#

# ╔═╡ ba17eeed-71d1-4322-a243-0c6555c9883b
for a in winners
for b in winners
for c in winners
	a == b || b == c || c == a && continue
	if @show ispartitioned(inputa, (a, b, c))
		println("Partitioned: $a, $b, $c")
	end
end
end
end

# ╔═╡ 93a677cb-3e50-4229-a4f0-e5062f53b5d5
md"## Results"

# ╔═╡ 6300a3cf-f6bf-4d94-ac12-c89c44d68b19
Runner.run_module(Day25, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─f05c84ea-4374-4925-9e86-d629c1bf5c07
# ╟─dadf8165-fbcf-4d42-b097-bf306d6cbaa7
# ╠═0fc73caf-1540-49f7-9f62-7fa9e7592048
# ╠═a754d8d8-3c39-459c-9af1-d45335ec0971
# ╠═c3e534c0-bd4d-44aa-bc36-8a8ded5dfb0d
# ╠═63ad9391-f0bd-48c1-9493-ff6a2f013f19
# ╠═10dffc73-567e-4806-82a2-dd1c8ddc20c0
# ╠═811d574b-c04e-4b8f-9b27-9a1deca733c9
# ╠═2f14a405-15a6-4559-ab67-896910e68ee9
# ╠═cbb02737-2804-43de-915b-b1ad74d3625e
# ╠═63ebfacb-4771-4042-9216-de294955b0fd
# ╠═aceedf67-e921-43c8-9b66-56e6e88a0798
# ╠═172156f9-8561-4df0-b890-d0854cb08a68
# ╠═f1ed9421-9ec8-47b4-8ecc-050221efef11
# ╠═39a16c5b-9a4d-422b-bb66-3825a4c15244
# ╠═e5e3c2b1-7133-4472-8d87-2e3b5a91c480
# ╠═8bdc86b9-fb4e-43c3-8ed6-9d5ea2984110
# ╠═1203330b-580e-4642-b665-9d3b2af0c766
# ╠═ba17eeed-71d1-4322-a243-0c6555c9883b
# ╟─93a677cb-3e50-4229-a4f0-e5062f53b5d5
# ╠═6300a3cf-f6bf-4d94-ac12-c89c44d68b19

### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 2b48e0be-c769-4519-8ac7-2ed6f330598a
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day15
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day15, Runner.inputfiles(); verbose=true)
  println("Day15 ready, just run() or Day15.part1(readlines(inputexample))")
end

# ╔═╡ 7dcff475-d468-42e8-b757-972666ee9637
@doc Day15

# ╔═╡ 461ed609-8f4e-46db-91f6-3c68974e7160
Runner.inputstats();

# ╔═╡ 63e86410-15da-4daa-b8b0-1e6feed1255e
begin
	function parseinput(lines)
		split(only(lines), ",")
		#Day15.parseinput(lines)
		#map(lines) do line
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		#end
	end
	function hashval(s::AbstractString)
		cur = 0
		for c in s
			cur += Int(c)
			cur *= 17
			cur %= 256
		end
		cur
	end
end;

# ╔═╡ b26a78de-3470-431e-965c-c0bdc4c8a665
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ 780c7ca3-13a5-4468-9d29-ecb38721410c
map(hashval, inputa) |> sum

# ╔═╡ 7e842977-d7c6-4366-ace6-ea3800ea79b8
length(inputa)

# ╔═╡ 744af492-d5e8-439c-bcba-1fab144e3485
struct Lens
	label::AbstractString
	power::Int
end

# ╔═╡ a15c3521-b725-4b57-8fa8-e88668b9da32
boxes = [Lens[] for _ in 1:256]

# ╔═╡ 5432fcd4-fb4c-469a-a693-043fd293abf6
for s in inputa
	if endswith(s, '-')
		label = chop(s)
		box = hashval(label) + 1
		i = findfirst(l -> l.label == label, boxes[box])
		if i !== nothing
			deleteat!(boxes[box], i)
		end
	else
		(label, power) = split(s, "=")
		box = hashval(label) + 1
		lens = Lens(label, parse(Int, power))
		i = findfirst(l -> l.label == label, boxes[box])
		if i === nothing
			push!(boxes[box], lens)
		else
			boxes[box][i] = lens
		end
	end
end

# ╔═╡ d89fc645-25f9-452f-b246-15f732e06631
boxes

# ╔═╡ 4f7961b4-3d5d-4aa9-939f-e6277ec36724
sum((i, lenses) -> sum(
	i*[j for (j, l) in enumerate(lenses)]),
	enumerate(boxes))

# ╔═╡ 9fd24e77-7d7c-4a28-81ad-721dc8833463
begin
	result = 0
	for (i, box) in enumerate(boxes)
		for (j, l) in enumerate(box)
			result += i * j * l.power
		end
	end
	result
end

# ╔═╡ c74ea7e2-074e-45e1-b7ed-2cbbaef3217f
md"## Results"

# ╔═╡ aa13f035-97c6-4ec5-81b6-c6ea9428d36e
Runner.run_module(Day15, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─7dcff475-d468-42e8-b757-972666ee9637
# ╟─2b48e0be-c769-4519-8ac7-2ed6f330598a
# ╠═461ed609-8f4e-46db-91f6-3c68974e7160
# ╠═63e86410-15da-4daa-b8b0-1e6feed1255e
# ╠═b26a78de-3470-431e-965c-c0bdc4c8a665
# ╠═780c7ca3-13a5-4468-9d29-ecb38721410c
# ╠═7e842977-d7c6-4366-ace6-ea3800ea79b8
# ╠═744af492-d5e8-439c-bcba-1fab144e3485
# ╠═a15c3521-b725-4b57-8fa8-e88668b9da32
# ╠═5432fcd4-fb4c-469a-a693-043fd293abf6
# ╠═d89fc645-25f9-452f-b246-15f732e06631
# ╠═4f7961b4-3d5d-4aa9-939f-e6277ec36724
# ╠═9fd24e77-7d7c-4a28-81ad-721dc8833463
# ╟─c74ea7e2-074e-45e1-b7ed-2cbbaef3217f
# ╠═aa13f035-97c6-4ec5-81b6-c6ea9428d36e

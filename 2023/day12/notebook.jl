### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 3034d811-660c-4e75-9bed-1541d3da5eda
begin
  import Pkg
  Pkg.activate()
  try
    @eval using Revise
  catch e
    @warn "Need to install Revise?" exception=(e)
  end
  using Day12
  using Runner
  inputexample = "input.example.txt"
  inputactual = "input.actual.txt"
  run() = Runner.run_module(Day12, Runner.inputfiles(); verbose=true)
  println("Day12 ready, just run() or Day12.part1(readlines(inputexample))")
end

# ╔═╡ 779bb886-a92d-4a5c-b6db-1a9c088f11d2
@doc Day12

# ╔═╡ 0ee8ac6c-8ef1-45cf-a95a-0d3ed4976c02
Runner.inputstats();

# ╔═╡ f407e58d-4b36-40ba-ab89-abe9f58c2290
begin
	struct Pattern
		chars::AbstractString
		runs::Vector{Int}
	end
	function parseinput(lines)
		#Day12.parseinput(lines)
		map(lines) do line
			chars, ints = split(line)
			Pattern(chars, parse.(Int, split(ints, ",")))
			#parse(Int, line)
			#if (m = match(r"^(\S+) (\S+)$", line)) !== nothing
			#  (foo, bar) = m.captures
			#end
		end
	end
end;

# ╔═╡ 439a8cc6-61a8-4bda-9d95-83e804598f87
begin # Useful variables
	exampleexpected = Runner.expectedfor(inputexample)
	examplelines = readlines(inputexample)
	actualexpected = Runner.expectedfor(inputactual)
	actuallines = readlines(inputactual)
	inputa = parseinput(actuallines)
	input = parseinput(examplelines)
end

# ╔═╡ c7e3eb9d-497f-4d9c-a971-1d38bcb064e0
length.(split(input[2].chars, '.'; keepempty=false)) == input[2].runs

# ╔═╡ 23038e60-3c8b-437d-a2a2-caaf33fe10d3
valid(pat::Pattern) = length.(split(pat.chars, '.'; keepempty=false)) == pat.runs

# ╔═╡ 8ad37ab3-d32e-464e-ae6a-86203b09d994
function valid_permutations(pat::Pattern)
	totalhash = sum(pat.runs)
	freehash = totalhash - count('#', pat.chars)
	#if freehash > 12
	#	println("$freehash free in $pat")
	#end
	if freehash == 0
		return 1
	end
	unknowns = findall('?', pat.chars)
	numunknown = length(unknowns)
	numunknown == 0 && error("no unknowns in $pat")
	perms = 0#Pattern[]
	iters = 0
	for x in (1<<freehash - 1):1<<numunknown
		iters+=1
		if count_ones(x) == freehash
			chars = collect(pat.chars)
			for (i, pos) in enumerate(unknowns)
				if x & (1<<(i-1)) > 0
					chars[pos] = '#'
				else
					chars[pos] = '.'
				end
			end
			#@show (chars, valid(Pattern(join(chars), pat.runs)))
			if valid(Pattern(join(chars), pat.runs))
				perms += 1
				#push!(perms, Pattern(join(chars), pat.runs))
			end
		end
	end
	#@show iters
	perms
end

# ╔═╡ b87cc882-c183-4684-97dc-1de363d5769c
valids = valid_permutations.(input)#; (valids, input[15])

# ╔═╡ 0e7f65bc-240a-4f6e-a8de-237cd97b641d
#sum(length.(valids))

# ╔═╡ c931b5c8-50cf-4583-93bc-e172a810982c
sum(valids)

# ╔═╡ c1e9e00f-704c-4e73-9815-cf7074916607
function valid_permutations2(pat::Pattern, charidx::Int, runidx::Int)
	#@show (charidx, runidx)
	if runidx > length(pat.runs)
		chars = collect(pat.chars)
		for i in charidx:length(chars)
			if chars[i] == '?'
				chars[i] = '.'
			end
		end
		p = Pattern(join(chars), pat.runs)
		#@show valid(p)
		return valid(p) ? 1 : 0
	end
	run = pat.runs[runidx]
	while charidx + run - 1 <= length(pat.chars) && pat.chars[charidx] == '.'
		charidx += 1
	end
	#@show "now $charidx $runidx"
	if charidx + run - 1 > length(pat.chars)
		#@show "$charidx too far"
		return 0
	end
	perms = 0
	for j in charidx:(length(pat.chars)-(run-1))
		if j > 1 && pat.chars[j-1] == '#'
			continue
		end
		runend = j + (run-1)
		if runend < length(pat.chars) && pat.chars[runend+1] == '#'
			continue # would be adjacent to the next block
		end
		chars = collect(pat.chars)
		for i in 1:(j-1)
			if chars[i] == '?'
				chars[i] = '.'
			end
		end
		good = true
		for i in j:runend
			if chars[i] == '.'
				good = false # invalid start position for run
			end
			chars[i] = '#'
		end
		if good
		#@show chars
			next = Pattern(join(chars), pat.runs)
			perms += valid_permutations2(next, runend+1, runidx + 1)
		end
		if pat.chars[j] == '#'
			break # only loop through unknowns, otherwise this is fixed
		end
	end
	#@show perms
	perms
end


# ╔═╡ 7f6fbbf2-283b-4ef2-b894-92e16b86d226
big = map(input) do p
	copies = [p.chars for _ in 1:5]
	Pattern(join(copies, "?"), repeat(p.runs, 5))
end

# ╔═╡ 85b8dcb9-6b40-4e95-af0b-ed339606ee9b
valids2 = valid_permutations2.(big, 1, 1)

# ╔═╡ ccfb7e3b-e419-4bda-ad8f-e94f58e2d4bc
sum(valids2)

# ╔═╡ 7bfd5ddd-e2c5-437d-bdd0-872ed28179aa
md"## Results"

# ╔═╡ 567d3024-29a7-4f39-b766-b81dd49c70cd
Runner.run_module(Day12, [
inputexample,
inputactual,
], verbose=true)

# ╔═╡ Cell order:
# ╟─779bb886-a92d-4a5c-b6db-1a9c088f11d2
# ╟─3034d811-660c-4e75-9bed-1541d3da5eda
# ╠═0ee8ac6c-8ef1-45cf-a95a-0d3ed4976c02
# ╠═f407e58d-4b36-40ba-ab89-abe9f58c2290
# ╠═439a8cc6-61a8-4bda-9d95-83e804598f87
# ╠═c7e3eb9d-497f-4d9c-a971-1d38bcb064e0
# ╠═23038e60-3c8b-437d-a2a2-caaf33fe10d3
# ╠═8ad37ab3-d32e-464e-ae6a-86203b09d994
# ╠═b87cc882-c183-4684-97dc-1de363d5769c
# ╠═0e7f65bc-240a-4f6e-a8de-237cd97b641d
# ╠═c931b5c8-50cf-4583-93bc-e172a810982c
# ╠═c1e9e00f-704c-4e73-9815-cf7074916607
# ╠═7f6fbbf2-283b-4ef2-b894-92e16b86d226
# ╠═85b8dcb9-6b40-4e95-af0b-ed339606ee9b
# ╠═ccfb7e3b-e419-4bda-ad8f-e94f58e2d4bc
# ╟─7bfd5ddd-e2c5-437d-bdd0-872ed28179aa
# ╠═567d3024-29a7-4f39-b766-b81dd49c70cd
